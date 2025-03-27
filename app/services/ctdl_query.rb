require 'ctdl_subclasses_resolver'
require 'find_uri_aliases'
require 'indexed_envelope_resource'
require 'indexed_envelope_resource_reference'
require 'json_context'
require 'postgres_ext'

# Executes a CTDL query over indexed envelope resources
class CtdlQuery # rubocop:todo Metrics/ClassLength
  ANY_VALUE = 'search:anyValue'.freeze

  DICTIONARIES = {
    'en' => 'english',
    'es' => 'spanish',
    'fr' => 'french',
    'nl' => 'dutch'
  }.freeze

  FTS_RANK = 'rank'.freeze

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

  SUBCLASS_OF = 'search:subClassOf'.freeze

  TYPES = {
    'xsd:boolean' => :boolean,
    'xsd:date' => :date,
    'xsd:decimal' => :decimal,
    'xsd:dateTime' => :datetime,
    'xsd:float' => :float,
    'xsd:integer' => :integer
  }.freeze

  Union = Struct.new(:name, :relation, keyword_init: true)

  attr_reader :condition, :envelope_community, :fts_ranks, :name, :order_by,
              :project, :query, :ref, :ref_table, :reverse_ref, :skip,
              :subqueries, :subresource_uris, :table, :take, :unions,
              :with_metadata

  delegate :columns_hash, to: IndexedEnvelopeResource
  delegate :context, to: JsonContext
  delegate :to_sql, to: :data_query

  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/ParameterLists
  def initialize( # rubocop:todo Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists
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
    # rubocop:enable Metrics/ParameterLists
    @envelope_community = envelope_community
    @fts_ranks = []
    @name = name
    @order_by = order_by

    @query = query
    @ref = ref
    @ref_table = IndexedEnvelopeResourceReference.arel_table
    @reverse_ref = reverse_ref
    @skip = skip
    @subqueries = []
    @table = IndexedEnvelopeResource.arel_table
    @take = take
    @unions = []
    @with_metadata = with_metadata

    @condition = build(query) unless subresource_uris
    @project = Array.wrap(project).map { _1.is_a?(Symbol) ? table[_1] : _1 }
  end
  # rubocop:enable Metrics/MethodLength

  def self.find_dictionary(locale)
    language, = locale&.split(/[-_]/)
    DICTIONARIES.fetch(language, 'english')
  end

  def count_query
    @count_query ||= Arel::SelectManager.new
                                        .from(relation.as('t'))
                                        .project(Arel.star.count.as('total_count'))
  end

  # rubocop:todo Metrics/MethodLength
  def data_query # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @data_query ||= begin
      columns = %w[ceterms:ctid payload search:recordCreated search:recordUpdated]

      if with_metadata
        columns += %w[search:recordOwnedBy search:recordPublishedBy search:resourcePublishType]
      end

      cte = Arel::Nodes::As.new(
        matched_resources_table,
        relation.dup.project(*columns.map { table[_1] })
      )

      cte_colums = ['@id', *columns].map { matched_resources_table[_1] }

      query = Arel::SelectManager.new
                                 .with(cte)
                                 .project([*cte_colums,
                                           matched_resources_table[FTS_RANK].sum.as(FTS_RANK)])
                                 .from(matched_resources_table)
                                 .group(*cte_colums)

      query.order(order) if order_by
      query.skip(skip) if skip
      query.take(take) if take
      query
    end
  end
  # rubocop:enable Metrics/MethodLength

  def fts_rank
    @fts_rank ||= begin
      ranks = [
        *fts_ranks,
        *[*subqueries, *unions].map { Arel::Table.new(_1.name)[FTS_RANK] }
      ]

      # rubocop:todo Style/NumberedParametersLimit
      rank = ranks.inject { Arel::Nodes::InfixOperation.new('+', _1, _2) }
      # rubocop:enable Style/NumberedParametersLimit
      rank || Arel.sql('1')
    end
  end

  def join_column
    @join_column ||= ref ? ref_table[subresource_column] : table[:@id]
  end

  def ref_only? # rubocop:todo Metrics/AbcSize
    return true unless query.is_a?(Array) || query.is_a?(Hash)

    condition =
      if query.is_a?(Array)
        return false unless query.size == 1

        query.first

      else
        query
      end

    condition.size == 1 && context.dig(condition.keys.first, '@type') == '@id'
  end

  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def relation # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
    @relation ||= begin
      relation = ref.nil? ? table : ref_table
      relation = relation.where(condition) if condition

      if subresource_uris && !subresource_uris.include?(ANY_VALUE)
        conditions = subresource_uris
                     .flat_map { |value| FindUriAliases.call(value) }
                     .compact
                     .map { |value| ref_table[subresource_column].matches("%#{value}%") }

        relation = relation.where(combine_conditions(conditions, :or)) if conditions.any?
      end

      relation = if ref
                   relation
                     .where(ref_table[:path].eq(ref))
                     .project(
                       ref_table[resource_column].as('resource_uri'),
                       fts_rank.as(FTS_RANK)
                     )
                 else
                   relation
                     .where(table[:'ceterms:ctid'].not_eq(nil))
                     .where(table[:envelope_community_id].eq(envelope_community.id))
                     .project(table[:@id], fts_rank.as(FTS_RANK))
                 end

      subquery_ctes = subqueries.map do |subquery|
        cte_table = Arel::Table.new(subquery.name)
        cte = Arel::Nodes::As.new(cte_table, subquery.relation)

        relation
          .join(cte_table, Arel::Nodes::OuterJoin)
          .on(cte_table[:resource_uri].eq(join_column))

        unless subquery.ref_only?
          subquery
            .relation
            .join(table)
            .on(table[:@id].eq(ref_table[subquery.subresource_column]))
        end

        cte
      end

      union_ctes = unions.map do |union|
        cte_table = Arel::Table.new(union.name)
        cte = Arel::Nodes::As.new(cte_table, union.relation)

        relation
          .join(cte_table, Arel::Nodes::OuterJoin)
          .on(cte_table[:@id].eq(join_column))

        cte
      end

      ctes = [*subquery_ctes, *union_ctes]
      relation.with(ctes) if ctes.any?
      relation.distinct
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def resource_column
    reverse_ref ? :subresource_uri : :resource_uri
  end

  def rows
    IndexedEnvelopeResource.connection.execute(data_query.to_sql)
  end

  def subresource_column
    reverse_ref ? :resource_uri : :subresource_uri
  end

  def total_count
    IndexedEnvelopeResource
      .connection
      .execute(count_query.to_sql)
      .first
      .fetch('total_count')
  end

  private

  def build(node)
    operator = find_operator(node)
    return unionize_conditions(node) if node.is_a?(Hash) && operator == :or

    combine_conditions(build_node(node).compact, find_operator(node))
  end

  def build_array_condition(key, value) # rubocop:todo Metrics/AbcSize
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

  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  def build_condition(key, value) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity
    negative = key.starts_with?('!')
    key = key.tr('!', '')
    reverse_ref = key.starts_with?('^')
    key = key.tr('^', '')

    column = columns_hash[key]
    context_entry = context[key]
    raise "Unsupported property: `#{key}`" unless context_entry || column

    context_entry ||= {}

    if context_entry['@type'] == '@id'
      condition = build_subquery_condition(key, value, reverse_ref)
      return negative ? Arel::Nodes::Not.new(condition) : condition
    end

    return IMPOSSIBLE_CONDITION unless column

    search_value = build_search_value(value)
    match_type = search_value.match_type if search_value.is_a?(SearchValue)
    fts_condition = match_type.nil? || match_type == 'search:contain'

    condition =
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

    negative ? Arel::Nodes::Not.new(condition) : condition
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

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

    node.filter_map do |key, value|
      next if key == 'search:operator'

      build_condition(key, value)
    end
  end

  # rubocop:todo Metrics/MethodLength
  def build_fts_condition(config, key, term) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    return table[key].not_eq(nil) if term == ANY_VALUE
    return no_value_scalar_condition(key) if term == NO_VALUE

    if term.is_a?(Array)
      conditions = term.map { |t| build_fts_condition(config, key, t) }
      return combine_conditions(conditions, :or)
    end

    term = term['search:value'] if term.is_a?(Hash)
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
          Arel::Nodes::SqlLiteral.new('text')
        )
      ]
    )

    or_query_vector = Arel::Nodes::NamedFunction.new(
      'replace',
      [
        text_query_vector,
        Arel::Nodes.build_quoted('&'),
        Arel::Nodes.build_quoted('|')
      ]
    )

    prefix_query_vector = Arel::Nodes::NamedFunction.new(
      'regexp_replace',
      [
        or_query_vector,
        Arel::Nodes.build_quoted('\w(\')'),
        Arel::Nodes.build_quoted('\&:*')
      ]
    )

    final_query_vector = Arel::Nodes::NamedFunction.new(
      'cast',
      [
        Arel::Nodes::As.new(
          prefix_query_vector,
          Arel::Nodes::SqlLiteral.new('tsquery')
        )
      ]
    )

    ts_rank = table.coalesce(
      Arel::Nodes::NamedFunction.new(
        'ts_rank_cd',
        [column_vector, final_query_vector]
      ),
      0
    )

    custom_rank = Arel::Nodes::NamedFunction.new(
      'ctdl_ts_rank',
      [table[key], Arel::Nodes.build_quoted(term)]
    )

    fts_ranks << Arel::Nodes::InfixOperation.new('+', ts_rank, custom_rank)
    Arel::Nodes::InfixOperation.new('@@', column_vector, final_query_vector)
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:todo Metrics/MethodLength
  def build_fts_conditions(key, value) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    conditions = value.items.map do |item|
      case item
      when Hash
        conditions = item.map do |locale, term|
          name = "#{key}_#{locale.tr('-', '_').downcase}"
          column = columns_hash[name]
          next IMPOSSIBLE_CONDITION unless column

          build_fts_condition(self.class.find_dictionary(locale), name, term)
        end
      when SearchValue
        build_fts_condition('english', key, item.items)
      when String
        build_fts_condition('english', key, item)
      else
        raise "FTS condition should be either an object or a string, `#{item}` is neither"
      end
    end.flatten

    combine_conditions(conditions, value.operator)
  end
  # rubocop:enable Metrics/MethodLength

  def build_id_condition(key, values)
    conditions = values.map do |value|
      if full_id_value?(key, value)
        table[key].eq(value)
      elsif value == ANY_VALUE
        table[key].not_eq(nil)
      elsif value == NO_VALUE
        table[key].eq(nil)
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

  def build_scalar_condition(key, value) # rubocop:todo Metrics/AbcSize
    datatype = TYPES.fetch(context.dig(key, '@type'), :string)

    value.items = resolve_type_value(value) if key == '@type'

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

  def build_search_value(value) # rubocop:todo Metrics/MethodLength
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
      if value.key?('search:value')
        SearchValue.new(
          Array(value['search:value']),
          find_operator(value),
          value['search:matchType']
        )
      else
        SearchValue.new([value], find_operator(value))
      end
    when String
      SearchValue.new([value])
    else
      value
    end
  end

  def build_subquery_condition(key, value, reverse)
    no_value = value == NO_VALUE
    subquery_name = generate_subquery_name

    subquery = CtdlQuery.new(
      no_value ? ANY_VALUE : value,
      envelope_community: envelope_community,
      name: subquery_name,
      ref: key,
      reverse_ref: reverse
    )

    subqueries << subquery
    column = Arel::Table.new(subquery_name)[:resource_uri]
    no_value ? column.eq(nil) : column.not_eq(nil)
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

  def generate_subquery_name
    loop do
      value = "t#{SecureRandom.hex(1)}"

      return value unless subqueries.any? { |s| s.name == value }
    end
  end

  def matched_resources_table
    @matched_resources_table ||= Arel::Table.new(:matched_resources)
  end

  def no_value_scalar_condition(key)
    combine_conditions([table[key].eq(nil), table[key].eq('')], :or)
  end

  def order
    direction = order_by.starts_with?('^') ? :desc : :asc
    key = order_by.tr('^', '')
    return unless SORT_OPTIONS.include?(key) || columns_hash.key?(key)

    column =
      if key == 'search:relevance'
        Arel::Nodes::SqlLiteral.new(FTS_RANK)
      else
        matched_resources_table[key]
      end

    column.send(direction)
  end

  def resolve_type_value(value)
    items = value.items.map do |item|
      next resolve_type_value(item) if item.is_a?(SearchValue)

      if value.match_type == SUBCLASS_OF
        CtdlSubclassesResolver
          .new(envelope_community:, root_class: item)
          .subclasses
      else
        FindUriAliases.call(item)
      end
    end

    items.flatten.compact.uniq
  end

  def subresource_uris # rubocop:todo Lint/DuplicateMethods
    return unless ref

    @subresource_uris ||= begin
      search_value = build_search_value(query)
      items = search_value.items if search_value.is_a?(SearchValue)
      items if items&.first.is_a?(String)
    end
  end

  def unionize_conditions(node)
    queries = node.except('search:operator').map do |key, value|
      CtdlQuery
        .new({ key => value }, envelope_community:, project: :@id)
        .relation
    end

    union = queries.inject do |union, query| # rubocop:todo Lint/ShadowingOuterLocalVariable
      Arel::Nodes::Union.new(union, query)
    end

    union_name = generate_subquery_name
    unions << Union.new(name: union_name, relation: union)
    Arel::Table.new(union_name)[:@id].not_eq(nil)
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
