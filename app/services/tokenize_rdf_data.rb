# Adds tokenized versions of string and URI values into the given graph
# for the purpose of custom full-text search in SPARQL
class TokenizeRdfData
  LANG_STRING_BACK_TRIM_LIMIT = 4

  LANG_STRING_BACK_TRIM_PERCENTAGE = 0.5

  LANG_STRING_FRONT_TRIM_LIMIT = 3

  LANG_STRING_FRONT_TRIM_PERCENTAGE = 0.3

  LANG_STRING_INCLUDE_VERBATIM_TOKENS = false

  LANG_STRING_JUNK_WORDS = %w[
    a and for had has have her his is or that the their theirs them they this those
  ].freeze

  LANG_STRING_MIN_TOKEN_LENGTH = 3

  PLAIN_STRING_INCLUDE_VERBATIM_TOKENS = false

  PLAIN_STRING_JUNK_WORDS = [].freeze

  PLAIN_STRING_TOKENIZE_CTIDS = false

  PREDICATE_PREFIX = RDF::URI.new('https://credreg.net/')

  REGISTRY_DOMAIN = 'credentialengineregistry.org'

  TOKENIZE_REGISTRY_URIS = false

  URI_INCLUDE_VERBATIM_TOKENS = false

  URI_MAIN_PART_JUNK_WORDS = %w[.com .edu .gov .net .org .php www.].freeze

  URI_MAIN_PART_MIN_TOKEN_LENGTH = 3

  URI_MIN_QUERY_PARAM_KEY_TOKEN_LENGTH = 3

  URI_MIN_QUERY_PARAM_VALUE_TOKEN_LENGTH = 3

  URI_QUERY_PARAM_KEY_JUNK_WORDS = [].freeze

  URI_QUERY_PARAM_VALUE_JUNK_WORDS = [].freeze

  URI_TOKENIZE_QUERY_PARAM_KEYS = false

  URI_TOKENIZE_QUERY_PARAM_VALUES = true

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

  def build_token_data_node(statement, value, verbatim)
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

    if verbatim
      graph << [
        node,
        PREDICATE_PREFIX + '__tokenFullVerbatim',
        statement.object
      ]
    end

    node
  end

  def build_token_set_node(token_data_node, word, count)
    node = RDF::Node.new
    graph << [token_data_node, PREDICATE_PREFIX + '__tokenSet', node]
    graph << [node, PREDICATE_PREFIX + '__tokenText', word]
    graph << [node, PREDICATE_PREFIX + '__tokenCount', count]
    node
  end

  def build_token_set_nodes(token_data_node, words)
    words.group_by(&:itself).each do |word, group|
      build_token_set_node(token_data_node, word, group.size)
    end
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

    useful_words = all_words.reject do |word|
      word.size < LANG_STRING_MIN_TOKEN_LENGTH ||
        LANG_STRING_JUNK_WORDS.include?(word)
    end

    token_data_node = build_token_data_node(
      statement,
      normalized_value,
      LANG_STRING_INCLUDE_VERBATIM_TOKENS
    )

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

    useful_words.group_by(&:itself).each do |word, group|
      token_set_node = build_token_set_node(
        token_data_node,
        word,
        group.size
      )

      back_trim_limit = [
        LANG_STRING_BACK_TRIM_LIMIT,
        word.size * LANG_STRING_BACK_TRIM_PERCENTAGE
      ].min

      (1..back_trim_limit).each do |trim|
        graph << [
          token_set_node,
          PREDICATE_PREFIX + '__tokenText',
          word[0, word.size - trim]
        ]
      end

      front_trim_limit = [
        LANG_STRING_FRONT_TRIM_LIMIT,
        word.size * LANG_STRING_FRONT_TRIM_PERCENTAGE
      ].min

      (1..front_trim_limit).each do |trim|
        graph << [
          token_set_node,
          PREDICATE_PREFIX + '__tokenText',
          word[trim, word.size]
        ]
      end
    end
  end

  def tokenize_plain_string(statement)
    return if statement.predicate.value =~ /__payload$/

    if !PLAIN_STRING_TOKENIZE_CTIDS && statement.predicate.value =~ /ctid$/i
      return
    end
    
    all_words = statement.object.value
      .downcase
      .split(/[^A-Za-z0-9]/)
      .map(&:strip)

    return if all_words.empty?

    normalized_value = all_words.split(' ')

    useful_words = all_words.reject do |word|
      PLAIN_STRING_JUNK_WORDS.include?(word)
    end

    token_data_node = build_token_data_node(
      statement,
      normalized_value,
      PLAIN_STRING_INCLUDE_VERBATIM_TOKENS
    )

    build_token_set_nodes(token_data_node, useful_words)
  end

  def tokenize_uri(statement)
    uri = URI(statement.object)
    return if !TOKENIZE_REGISTRY_URIS && uri.host == REGISTRY_DOMAIN

    uri.path = uri.path.gsub(/\/$/, '') if uri.path.present?
    uri.query = uri.query.gsub(/\?$/, '') if uri.query.present?
    uri.scheme = nil
    normalized_value = uri.to_s.gsub(/^\/\//, '')
    return if normalized_value.blank?

    token_data_node = build_token_data_node(
      statement,
      normalized_value,
      URI_INCLUDE_VERBATIM_TOKENS
    )

    main_part = "#{uri.host}#{uri.path}"

    URI_MAIN_PART_JUNK_WORDS.each do |word|
      main_part.gsub!(word, '')
    end

    all_words = main_part
      .gsub(/[^A-Za-z0-9\/\._-]/, '')
      .split(/[-\.\/_]/)
      .map(&:strip)
      .select { |word| word.size >= URI_MAIN_PART_MIN_TOKEN_LENGTH }

    all_words.group_by(&:itself).each do |word, group|
      token_set_node = RDF::Node.new

      graph << [
        token_data_node,
        PREDICATE_PREFIX + '__tokenSet',
        token_set_node
      ]

      graph << [token_set_node, PREDICATE_PREFIX + '__tokenText', word]
      graph << [token_set_node, PREDICATE_PREFIX + '__tokenCount', group.size]
    end

    query = uri.query
    return if query.blank?

    unless URI_TOKENIZE_QUERY_PARAM_KEYS || URI_TOKENIZE_QUERY_PARAM_VALUES
      return
    end

    query_params = CGI.parse(query.gsub(/[^A-Za-z0-9\/\._\-\&=+]/, ''))

    if URI_TOKENIZE_QUERY_PARAM_KEYS
      useful_keys = query_params.keys.reject do |key|
        key.size < URI_MIN_QUERY_PARAM_KEY_TOKEN_LENGTH ||
          URI_QUERY_PARAM_KEY_JUNK_WORDS.include?(key)
      end

      build_token_set_nodes(token_data_node, useful_keys)
    end

    if URI_TOKENIZE_QUERY_PARAM_VALUES
      useful_values = query_params.values
        .map { |value| value.first.split(' ') }
        .flatten
        .reject do |value|
        value.size < URI_MIN_QUERY_PARAM_VALUE_TOKEN_LENGTH ||
          URI_QUERY_PARAM_VALUE_JUNK_WORDS.include?(value)
      end

      build_token_set_nodes(token_data_node, useful_values)
    end
  end
end
