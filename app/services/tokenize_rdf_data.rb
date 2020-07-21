# Adds tokenized versions of string and URI values into the given graph
# for the purpose of custom full-text search in SPARQL
class TokenizeRdfData
  PLAIN_STRING_TOKENIZE_CTIDS = false

  PREDICATE_PREFIX = RDF::URI.new('https://credreg.net/')

  REGISTRY_DOMAIN = 'credentialengineregistry.org'

  TOKENIZE_REGISTRY_URIS = false

  XSD_STRING_TYPE = 'http://www.w3.org/2001/XMLSchema#string'.freeze

  attr_reader :graph

  def initialize(graph)
    @graph = graph
  end

  def self.call(graph)
    new(graph).call
  end

  def call
    graph.each do |statement|
      object = statement.object

      if object.respond_to?(:language) && object.language.present?
        tokenize_lang_string(statement)
      elsif object.respond_to?(:datatype) && object.datatype == XSD_STRING_TYPE
        tokenize_plain_string(statement)
      elsif object.is_a?(RDF::URI)
        tokenize_uri(statement)
      end
    end
  end

  private

  def build_token_data_node(statement, value)
    node = RDF::Node.new

    graph << [
      statement.subject,
      RDF::URI.new("#{statement.predicate.value}__tokenData"),
      node
    ]

    graph << [node, PREDICATE_PREFIX + '__tokenFullNormalized', value]

    graph << [
      node,
      PREDICATE_PREFIX + '__tokenFullNormalizedLength',
      value.size
    ]

    node
  end

  def tokenize_lang_string(statement)
    all_words = statement.object.value
      .downcase
      .gsub("'s", '')
      .gsub(/[^A-Za-z0-9 ]/, ' ')
      .split(' ')
      .map(&:strip)

    normalized_value = all_words.join(' ')
    return if normalized_value.blank?

    token_data_node = build_token_data_node(statement, normalized_value)
    language_code = statement.object.language.downcase.to_s
    
    graph << [
      token_data_node,
      PREDICATE_PREFIX + '__tokenLanguage',
      language_code
    ]

    if language_code.include?('-')
      graph << [
        token_data_node,
        PREDICATE_PREFIX + '__tokenLanguage',
        language_code.split('-').first
      ]
    end
  end

  def tokenize_plain_string(statement)
    predicate = statement.predicate.value
    return if predicate.ends_with?('__payload')
    return if predicate.ends_with?('__plaintext')

    if !PLAIN_STRING_TOKENIZE_CTIDS && predicate.ends_with?('ctid')
      return
    end

    value = statement.object.value
    return unless value.is_a?(String)

    all_words = value
      .downcase
      .split(/[^A-Za-z0-9]/)
      .map(&:strip)

    return if all_words.empty?

    normalized_value = all_words.split(' ')

    build_token_data_node(statement, normalized_value)
  end

  def tokenize_uri(statement)
    uri = URI(statement.object)
    return if !TOKENIZE_REGISTRY_URIS && uri.host == REGISTRY_DOMAIN

    uri.path = uri.path.gsub(/\/$/, '') if uri.path.present?
    uri.query = uri.query.gsub(/\?$/, '') if uri.query.present?
    uri.scheme = nil
    normalized_value = uri.to_s.gsub(/^\/\//, '')
    return if normalized_value.blank?

    build_token_data_node(statement, normalized_value)
  end
end
