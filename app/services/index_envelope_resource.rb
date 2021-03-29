require 'indexed_envelope_resource'
require 'json_context'

# Flattens out envelope resources in order to simplify querying them in CTDL
class IndexEnvelopeResource
  AttributeSet = Struct.new(:attributes, :references)

  DICTIONARIES = {
    'en' => 'english',
    'es' => 'spanish',
    'fr' => 'french'
  }.freeze

  LOCK_NAME = 'index_envelope_resource'.freeze

  TYPES = {
     'xsd:boolean' => :boolean,
     'xsd:date' => :date,
     'xsd:decimal' => :decimal,
     'xsd:dateTime' => :datetime,
     'xsd:float' => :float,
     'xsd:integer' => :integer
   }.freeze

  attr_reader :columns, :envelope_resource

  delegate :add_column, :add_index, to: ActiveRecord::Migration
  delegate :context, to: JsonContext
  delegate :reset_column_information, :with_advisory_lock, to: IndexedEnvelopeResource

  def initialize(envelope_resource)
    @envelope_resource = envelope_resource
    assign_columns
  end

  def self.call(envelope_resource)
    IndexEnvelopeResource.new(envelope_resource).call
  end

  def call
    envelope_resource.indexed_envelope_resources.delete_all(:delete_all)
    payload = envelope_resource.processed_resource

    resources = build_attributes(payload).map do |set|
      resource = envelope_resource.indexed_envelope_resources.new(set.attributes)
      resource.run_callbacks(:save) { false }

      set.references.each do |key, subresource_uris|
        subresource_uris.each do |subresource_uri|
          resource.references.new(
            path: key,
            resource_uri: resource[:'@id'],
            subresource_uri: subresource_uri
          )
        end
      end

      resource
    end

    ActiveRecord::Base.transaction do
      IndexedEnvelopeResource.bulk_import!(resources, recursive: true)
    end
  end

  private

  def add_array_column(name, datatype)
    try_add_column(name) do
      return if columns.include?(name)

      add_column(
        :indexed_envelope_resources,
        name,
        datatype,
        array: true,
        default: [],
        null: false
      )

      column_name = name.include?(':') ? "\"#{name}\"" : name
      index_name = "i_ctdl_#{name.tr(':', '_')}"

      add_index(
        :indexed_envelope_resources,
        column_name,
        name: index_name,
        using: :gin
      )
    end
  end

  def add_string_column(name, language: nil)
    try_add_column(name) do
      return if columns.include?(name)

      add_column(:indexed_envelope_resources, name, :string)

      column_name = name.include?(':') ? "\"#{name}\"" : name
      index_name_prefix = "i_ctdl_#{name.tr(':', '_')}"
      dictionary = DICTIONARIES.fetch(language, 'english')

      add_index(
        :indexed_envelope_resources,
        "to_tsvector('#{dictionary}', translate(#{column_name}, '/.', ' '))",
        name: "#{index_name_prefix}_fts",
        using: :gin
      )

      add_index(
        :indexed_envelope_resources,
        name.to_sym,
        name: "#{index_name_prefix}_trgm",
        opclass: { name.to_sym => :gin_trgm_ops },
        using: :gin
      )
    end
  end

  def assign_columns
    @columns = Set.new(IndexedEnvelopeResource.columns_hash.keys)
  end

  def build_attributes(payload)
    envelope = envelope_resource.envelope

    resource_attributes = {
      '@id' => payload['@id'],
      '@type' => payload['@type'],
      'ceterms:ctid' => payload['ceterms:ctid'],
      'payload' => payload
    }

    references = {}
    subresources_attribute_sets = []

    payload.except('@context', '@id', '@type', 'ceterms:ctid').map do |key, value|
      context_entry = context[key]

      unless context_entry
        Airbrake.notify("Missing context entry for #{key}")
        next
      end

      type = context_entry['@type']

      if context_entry['@container'] == '@language'
        resource_attributes.merge!(process_language_map(key, value))
        next
      end

      if type == 'xsd:string'
        add_string_column(key)
        resource_attributes[key] = Array(value).join(' ')
        next
      end

      if type == '@id'
        subresource_uris, sets = process_reference(value)
        subresources_attribute_sets += sets
        references[key] = subresource_uris
      else
        add_array_column(key, TYPES.fetch(type, :string))
        resource_attributes[key] = Array(value)
      end
    end

    [
      AttributeSet.new(resource_attributes, references),
      *subresources_attribute_sets
    ]
  end

  def process_language_map(key, map)
    add_string_column(key)
    return { key => map } unless map.is_a?(Hash)

    attributes = map.map do |locale, value|
      language, territory = locale.downcase.split(/[-_]/)
      normalized_locale = [language, territory].compact.join('_')
      column = "#{key}_#{normalized_locale}"
      add_string_column(column, language: language)
      [column, value]
    end

    attributes.to_h.merge(key => map.values.join(' '))
  end

  def process_reference(value)
    subresources_attribute_sets = []

    ids = Array(value).map do |item|
      if item.is_a?(Hash)
        if item.key?('@id')
          item.fetch('@id')
        elsif item.key?('@type')
          id = "_:#{SecureRandom.uuid}"
          attribute_sets = build_attributes(item)
          attribute_sets.first.attributes['@id'] = id
          subresources_attribute_sets += attribute_sets
          id
        end
      else
        item
      end
    end

    [ids.compact.uniq, subresources_attribute_sets]
  end

  def reset_column_info
    IndexedEnvelopeResource.reset_column_information
    assign_columns
  end

  def try_add_column(name)
    return if columns.include?(name)

    with_advisory_lock(LOCK_NAME) do
      reset_column_info
      return if columns.include?(name)

      yield
      reset_column_info
    end
  end
end
