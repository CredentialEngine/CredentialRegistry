require 'indexed_envelope_resource'
require 'indexed_envelope_resource_reference'
require 'ctdl_subclasses_resolver'
require 'json_context'
require 'postgres_ext'

# Executes a CTDL query over indexed envelope resources
class CtdlQuery
  ANY_VALUE = 'search:anyValue'.freeze
  IMPOSSIBLE_CONDITION = Arel::Nodes::InfixOperation.new('=', 0, 1)

  MATCH_TYPES = %w[
    search:startsWith
    search:endsWith
    search:contains
    search:exactMatch
  ].freeze

  NO_VALUE = 'search:noValue'.freeze

  SearchValue = Struct.new(:items, :operator, :match_type)

  SORT_OPTIONS = %w[
    search:recordCreated
    search:recordUpdated
    search:relevance
  ].freeze

  TYPES = {
    'xsd:boolean' => :boolean,
    'xsd:date' => :date,
    'xsd:decimal' => :decimal,
    'xsd:dateTime' => :datetime,
    'xsd:float' => :float,
    'xsd:integer' => :integer
  }.freeze

  attr_reader :condition, :envelope_community, :fts_columns, :fts_ranks, :name,
              :order_by, :projections, :query, :ref, :reverse_ref, :skip,
              :subqueries, :subresource_uris, :table, :take, :with_metadata

  delegate :columns_hash, to: IndexedEnvelopeResource
  delegate :context, to: JsonContext

  def initialize(
    query,
    envelope_community:,
    name: nil,
    order_by: nil,
    project: [],
    ref: nil,
    reverse_ref: false,
    skip: nil,
    take: nil,
    with_metadata: false
  )
    @envelope_community = envelope_community
    @fts_columns = []
    @fts_ranks = []
    @name = name
    @order_by = order_by
    @projections = Array(project)
    @query = query
    @ref = ref
    @reverse_ref = reverse_ref
    @skip = skip
    @subqueries = []
    @table = IndexedEnvelopeResource.arel_table
    @take = take
    @with_metadata = with_metadata

    @condition = build(query) unless subresource_uris
  end

  def execute
    IndexedEnvelopeResource.connection.execute(to_sql)
  end

  def to_sql
    @sql ||= begin
      if subqueries.any?
        cte = <<~SQL.strip
          WITH #{subqueries.map { |q| "#{q.name} AS (#{q.to_sql})" }.join(', ')}
        SQL
      end

      ref_table = IndexedEnvelopeResourceReference.arel_table

      resource_column, subresource_column =
        if reverse_ref
          %i[subresource_uri resource_uri]
        else
          %i[resource_uri subresource_uri]
        end

      from_main_table = envelope_community.secured? || subresource_uris.nil?
      relation = from_main_table ? table : ref_table
      relation = relation.where(condition) if condition

      if subresource_uris && !subresource_uris.include?(ANY_VALUE)
        conditions = subresource_uris.map do |value|
          ref_table[subresource_column].matches("%#{value}%")
        end

        relation = relation.where(combine_conditions(conditions, :or))
      end

      if ref && from_main_table
        relation = relation
          .join(ref_table)
          .on(table[:@id].eq(ref_table[subresource_column]))

        relation =
          if envelope_community.secured?
            relation.where(
              combine_conditions(
                [
                  table[:envelope_community_id].eq(envelope_community.id),
                  table[:public_record].eq(true)
                ],
                :or
              )
            )
          else
            relation.where(table[:public_record].eq(true))
          end
      end

      if ref
        relation =
          relation
            .where(ref_table[:path].eq(ref))
            .project(ref_table[resource_column].as('resource_uri'))
      else
        relation = relation.skip(skip) if skip
        relation = relation.take(take) if take
        relation = relation.project(*[*projections, *(order_by && fts_columns)])
      end

      if ref.nil?
        relation = relation.where(
          table[:envelope_community_id].eq(envelope_community.id)
        )

        relation = relation.order(build_order_expression) if order_by

        if with_metadata
          relation = relation
            .project(
              table[:'search:recordCreated'],
              table[:'search:recordOwnedBy'],
              table[:'search:recordPublishedBy'],
              table[:'search:resourcePublishType'],
              table[:'search:recordUpdated']
            )
        end
      end

      [cte, relation.to_sql].join(' ').strip
    end
  end

  private

  def build(node)
    combine_conditions(build_node(node), find_operator(node))
  end

  def build_array_condition(key, value)
    value = SearchValue.new([value]) unless value.is_a?(SearchValue)
    return table[key].not_eq([]) if value.items.include?(ANY_VALUE)
    return table[key].eq([]) if value.items.include?(NO_VALUE)

    datatype = TYPES.fetch(context.dig(key, '@type'), :string)

    if value.items.size == 2 && datatype != :string
      return build_between_condition(
        Arel::Nodes::ArrayAccess.new(table[key], 1),
        value
      )
    end

    operator = value.operator == :and ? :contains : :overlap
    table[key].send(operator, value.items)
  end

  def build_between_condition(node, search_value)
    if search_value.items.map(&:presence).empty?
      raise "Invalid range: `#{search_value.items.to_json}`"
    end

    from, to = search_value.items
    return node.lteq(to) if from.blank?
    return node.gteq(from) if to.blank?

    node.between(Range.new(*search_value.items))
  end

  def build_condition(key, value)
    reverse_ref = key.starts_with?('^')
    key = key.tr('^', '')

    column = columns_hash[key]
    context_entry = context[key]
    raise "Unsupported property: `#{key}`" unless context_entry || column

    context_entry ||= {}

    if context_entry['@type'] == '@id'
      return build_subquery_condition(key, value, reverse_ref)
    end

    return IMPOSSIBLE_CONDITION unless column

    search_value = build_search_value(value)
    match_type = search_value.match_type if search_value.is_a?(SearchValue)
    fts_condition = match_type.nil? || match_type == 'search:contain'

    if %w[@id ceterms:ctid].include?(key)
      build_id_condition(key, search_value.items)
    elsif context_entry['@container'] == '@language'
      if fts_condition
        build_fts_conditions(key, search_value)
      else
        build_like_condition(key, search_value.items, match_type)
      end
    elsif context_entry['@type'] == 'xsd:string'
      if fts_condition
        build_fts_condition('english', key, search_value.items)
      else
        build_like_condition(key, search_value.items, match_type)
      end
    elsif column.array
      build_array_condition(key, search_value)
    else
      build_scalar_condition(key, search_value)
    end
  end

  def build_from_array(node)
    node.map { |item| build(item) }
  end

  def build_from_hash(node)
    node = node.fetch('search:value', node)
    return build_from_array(node) if node.is_a?(Array)

    if (term_group = node['search:termGroup'])
      conditions = build_from_hash(node.except('search:termGroup'))
      return conditions << build(term_group)
    end

    node.map do |key, value|
      next if key == 'search:operator'

      build_condition(key, value)
    end.compact
  end

  def build_fts_condition(config, key, term)
    return table[key].not_eq(nil) if term == ANY_VALUE
    return no_value_scalar_condition(key) if term == NO_VALUE

    if term.is_a?(Array)
      conditions = term.map { |t| build_fts_condition(config, key, t) }
      return combine_conditions(conditions, :or)
    end

    term = term.fetch('search:value') if term.is_a?(Hash)
    quoted_config = Arel::Nodes.build_quoted(config)

    translated_column = Arel::Nodes::NamedFunction.new(
      'translate',
      [
        table[key],
        Arel::Nodes.build_quoted('/.'),
        Arel::Nodes.build_quoted(' ')
      ]
    )

    translated_term = Arel::Nodes::NamedFunction.new(
      'translate',
      [
        Arel::Nodes.build_quoted(term),
        Arel::Nodes.build_quoted('/.'),
        Arel::Nodes.build_quoted(' ')
      ]
    )

    column_vector = Arel::Nodes::NamedFunction.new(
      'to_tsvector',
      [quoted_config, translated_column]
    )

    query_vector = Arel::Nodes::NamedFunction.new(
      'plainto_tsquery',
      [quoted_config, translated_term]
    )

    text_query_vector = Arel::Nodes::NamedFunction.new(
      'cast',
      [
        Arel::Nodes::As.new(
          query_vector,
          Arel::Nodes::SqlLiteral.new('text'),
        )
      ]
    )

    or_query_vector = Arel::Nodes::NamedFunction.new(
      'replace',
      [
        text_query_vector,
        Arel::Nodes.build_quoted('&'),
        Arel::Nodes.build_quoted('|'),
      ]
    )

    prefix_query_vector = Arel::Nodes::NamedFunction.new(
      'regexp_replace',
      [
        or_query_vector,
        Arel::Nodes.build_quoted('\w(\')'),
        Arel::Nodes.build_quoted('\&:*'),
      ]
    )

    final_query_vector = Arel::Nodes::NamedFunction.new(
      'cast',
      [
        Arel::Nodes::As.new(
          prefix_query_vector,
          Arel::Nodes::SqlLiteral.new('tsquery'),
        )
      ]
    )

    fts_columns << table[key]

    fts_ranks << table.coalesce(
      Arel::Nodes::NamedFunction.new(
        'ts_rank',
        [column_vector, final_query_vector]
      ),
      0
    )

    Arel::Nodes::InfixOperation.new('@@', column_vector, final_query_vector)
  end

  def build_fts_conditions(key, value)
    conditions = value.items.map do |item|
      if item.is_a?(Hash)
        conditions = item.map do |locale, term|
          name = "#{key}_#{locale.tr('-', '_').downcase}"
          column = columns_hash[name]
          next IMPOSSIBLE_CONDITION unless column

          config =
            if locale.starts_with?('es')
              'spanish'
            elsif locale.starts_with?('fr')
              'french'
            else
              'english'
            end

          build_fts_condition(config, name, term)
        end
      elsif item.is_a?(SearchValue)
        build_fts_condition('english', key, item.items)
      elsif item.is_a?(String)
        build_fts_condition('english', key, item)
      else
        raise "FTS condition should be either an object or a string, `#{item}` is neither"
      end
    end.flatten

    combine_conditions(conditions, value.operator)
  end

  def build_id_condition(key, values)
    conditions = values.map do |value|
      if full_id_value?(key, value)
        table[key].eq(value)
      else
        table[key].matches("%#{value}%")
      end
    end

    combine_conditions(conditions, :or)
  end

  def build_like_condition(key, values, match_type)
    conditions = values.map do |value|
      value =
        case match_type
        when 'search:contains' then "%#{value}%"
        when 'search:endsWith' then "%#{value}"
        when 'search:exactMatch' then value
        when 'search:startsWith' then "#{value}%"
        else raise "Unsupported search:matchType: `#{match_type}`. " \
                   "Supported values: #{MATCH_TYPES.map { |t| "`#{t}`" }.join(', ')}"
        end

      table[key].matches(value)
    end

    combine_conditions(conditions, :or)
  end

  def build_node(node)
    case node
    when Array then build_from_array(node)
    when Hash then build_from_hash(node)
    else raise "Either an array or object is expected, `#{node}` is neither"
    end
  end

  def build_order_expression
    direction = order_by.starts_with?('^') ? :desc : :asc
    key = order_by.tr('^', '')

    normalized_key = key if SORT_OPTIONS.include?(key) || columns_hash.key?(key)
    normalized_key = nil if fts_ranks.empty? && key == 'search:relevance'
    normalized_key ||= fts_ranks.any? ? 'search:relevance' : 'search:recordCreated'

    property =
      if normalized_key == 'search:relevance'
        if fts_ranks.size > 1
          fts_ranks.inject do |result, rank|
            Arel::Nodes::InfixOperation.new('+', result, rank)
          end
        else
          fts_ranks.first
        end
      else
        table[normalized_key]
      end

    property.send(direction)
  end

  def build_scalar_condition(key, value)
    datatype = TYPES.fetch(context.dig(key, '@type'), :string)

    if key == "@type" && value.match_type == "search:subClassOf"
      value = resolve_subclass_of_value(key, value)
    end


    if %w[@id ceterms:ctid].include?(key)
      build_id_condition(key, value.items)
    elsif value.items.size == 2 && datatype != :string
      build_between_condition(table[key], value)
    elsif value.items.include?(ANY_VALUE)
      table[key].not_eq(nil)
    elsif value.items.include?(NO_VALUE)
      no_value_scalar_condition(key)
    else
      table[key].in(value.items)
    end
  end

  def resolve_subclass_of_value(key, value)
    items = value.items.flat_map do |cls|
      CtdlSubclassesResolver.new(root_class: cls).subclasses
    end.uniq

    SearchValue.new(items)
  end

  def build_search_value(value)
    case value
    when Array
      items =
        if value.first.is_a?(String)
          value
        else
          value.map { |item| build_search_value(item) }
        end

      SearchValue.new(items, :or)
    when Hash
      if (internal_value = value['search:value']).present?
        SearchValue.new(
          Array(internal_value),
          find_operator(value),
          value['search:matchType']
        )
      else
        SearchValue.new([value])
      end
    when String
      SearchValue.new([value])
    else
      value
    end
  end

  def build_subquery_condition(key, value, reverse)
    subquery_name = generate_subquery_name(key)

    subqueries << CtdlQuery.new(
      value == NO_VALUE ? ANY_VALUE : value,
      envelope_community: envelope_community,
      name: subquery_name,
      ref: key,
      reverse_ref: reverse
    )

    table[:'@id'].send(
      value == NO_VALUE ? :not_in : :in,
      Arel.sql("(SELECT DISTINCT resource_uri FROM #{subquery_name})")
    )
  end

  def combine_conditions(conditions, operator)
    conditions.inject { |result, condition| result.send(operator, condition) }
  end

  def find_operator(node)
    return :or if node.is_a?(Array)

    node['search:operator'] == 'search:orTerms' ? :or : :and
  end

  def full_id_value?(key, value)
    case key
    when '@id' then valid_bnode?(value) || valid_uri?(value)
    when 'ceterms:ctid' then valid_ceterms_ctid?(value)
    else false
    end
  end

  def generate_subquery_name(key)
    loop do
      value = "q_#{SecureRandom.hex}"

      return value unless subqueries.any? { |s| s.name == value }
    end
  end

  def no_value_scalar_condition(key)
    combine_conditions([table[key].eq(nil), table[key].eq('')], :or)
  end

  def subresource_uris
    return unless ref

    @subresource_uris ||= begin
      search_value = build_search_value(query)
      items = search_value.items if search_value.is_a?(SearchValue)
      items if items&.first.is_a?(String)
    end
  end

  def valid_bnode?(value)
    !!UUID.validate(value[2..value.size - 1])
  end

  def valid_ceterms_ctid?(value)
    !!UUID.validate(value[3..value.size - 1])
  end

  def valid_uri?(value)
    URI.parse(value).is_a?(URI::HTTP)
  rescue URI::InvalidURIError
    false
  end
end
