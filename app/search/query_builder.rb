module Search
  # ES query builder for the documents repository
  class QueryBuilder
    attr_reader :query, :terms

    # Usage:
    #     QueryBuilder(search_terms, pagination_terms).query
    #
    # E.g:
    #   Match all:  QueryBuilder(nil).query
    #   FTS only:   QueryBuilder(fts: 'something').query
    #   Date only:  QueryBuilder(date: {from: '2016-08-10'}).query
    def initialize(terms, options)
      @terms = terms
      @options = options
      @query = nil

      build
    end

    # Build query
    # If the @terms is nil, then we match_all, else build a bool query
    def build
      @terms.nil? ? build_match_all : build_bool_query
    end

    # paginated match_all query
    def build_match_all
      @query = {
        query: { match_all: {} },
        size: limit,
        from: (page - 1) * limit
      }
    end

    def build_bool_query
      @query = bool_query

      build_fts if @terms[:fts]
      build_date_range if filter_by_date_range?

      [:should, :must].each do |clause|
        @terms.fetch(clause, {}).each do |prop, val|
          send(:"add_#{clause}", prop, val)
        end
      end
    end

    def bool_query
      {
        query: { bool: { should: [], must: [] } },
        size: limit,
        from: (page - 1) * limit
      }
    end

    # if a 'fts' term is provided, we do a fuzzy text query using n-grams on
    # the _fts field
    def build_fts
      # add_should('_fts.full', @terms[:fts])
      add_should('_fts.partial', @terms[:fts])
    end

    # whether we should filter by date_range or not
    def filter_by_date_range?
      date = @terms[:date]
      # filter by date only if one of the 'from' or 'until' terms are provided
      date && (date[:from].present? || date[:until].present?)
    end

    # Build date range filter term
    def build_date_range
      @query[:query][:bool][:must] << {
        range: {
          date: {
            gte: @terms[:date][:from],
            lte: @terms[:date][:until],
            boost: 0
          }.compact
        }
      }
    end

    # Minimun matching score (used for should clauses, for now only _fts)
    def min_score
      0.6
    end

    # Add a should clause on the bool query
    # Params:
    #  - prop: [String] property name
    #  - value: [String] value
    #  - boost: [Integer] weight of this prop on the score
    def add_should(prop, value, boost = 1)
      @query[:min_score] = min_score unless @query[:min_score]
      term = { match: { prop => { query: value, boost: boost } } }
      @query[:query][:bool][:should] << term
    end

    # Add a filter clause on the bool query
    # Params:
    #  - prop: [String] property name
    #  - value: [String] value
    # def add_filter(attr, value)
    #   term = if value.is_a? Array
    #            { terms: { attr => value } }
    #          else
    #            { match: { attr => { query: value } } }
    #          end
    #   @query[:query][:bool][:filter] << term
    # end

    # Add a must clause on the bool query
    # Params:
    #  - prop: [String] property name
    #  - value: [String] value
    def add_must(attr, value)
      @query[:query][:bool][:must] << {
        match: { attr => { query: value, boost: 0 } }
      }
    end

    # Pagination param for the 'per_page'. It 'limits' the response size.
    def limit
      @options.fetch(:per_page, 20)
    end

    # Pagination param for the 'page'.
    def page
      @options.fetch(:page, 1)
    end
  end
end
