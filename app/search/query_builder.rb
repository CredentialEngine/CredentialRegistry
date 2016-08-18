module Search
  # ES query builder for the documents repository
  class QueryBuilder
    attr_reader :query, :terms

    def initialize(terms, options)
      @terms = terms
      @options = options
      @query = nil

      build
    end

    def build
      @terms.nil? ? build_match_all : build_bool_query
    end

    def build_match_all
      @query = {
        query: { bool: { must: { match_all: {} } } },
        size: limit,
        from: (page - 1) * limit
      }
    end

    def build_bool_query
      @query = bool_query

      add_should('_fts.partial', @terms[:fts]) if @terms[:fts]

      [:should, :must, :filter].each do |clause|
        @terms.fetch(clause, {}).each do |prop, val|
          send(:"add_#{clause}", prop, val)
        end
      end
    end

    def bool_query
      {
        query: { bool: { should: [], must: [], filter: [] } },
        size: limit,
        from: (page - 1) * limit
      }
    end

    def add_should(prop, value)
      @query[:min_score] = 0.8 unless @query[:min_score]
      @query[:query][:bool][:should] << { match: { prop => { query: value } } }
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
