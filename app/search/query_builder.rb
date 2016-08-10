module Search
  # ES query builder for the documents repository
  class QueryBuilder
    attr_reader :query

    def initialize(term, options)
      @term = term
      @options = options
      @query = nil

      build
    end

    def build
      @query = if @term.nil?
                 match_all
               elsif @term.respond_to?(:to_hash)
                 @term
               else
                 fuzzy_query(@term.downcase)
               end
    end

    def match_all
      { query: { bool: { must: { match_all: {} } } } }
    end

    def fuzzy_query(_term)
      {
        min_score: 0.5,
        query: { bool: { should: [], must: [], filter: [] } },
        size: limit,
        from: (page - 1) * limit
      }
    end

    def should_clauses
      [
        # { match: { 'bla.full' => {query: term, type: 'phrase', boost: 8} } },
        # { match: { 'bla.partial' => {query: term, boost: 4} } },
      ]
    end

    def add_filter(attr, value)
      filter_term = if value.is_a? Array
                      { terms: { attr => value } }
                    else
                      { match: { attr => { query: value } } }
                    end
      @query[:query][:bool][:filter] << filter_term
    end

    def add_must(attr, value)
      @query[:query][:bool][:must] << { match: { attr => { query: value } } }
    end

    def limit
      @options.fetch(:per_page, 20)
    end

    def page
      @options.fetch(:page, 1)
    end
  end
end
