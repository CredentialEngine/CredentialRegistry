module Search
  # encapsulates ES responses to be compatible with api-pagination
  class Response
    include Enumerable
    attr_reader :es_response, :hits, :options

    def initialize(es_response, options = {})
      @es_response = es_response.response
      @hits = es_response.to_a
      @options = options.blank? ? { per_page: 20, page: 1 } : options
    end

    # Iterate using the Envelope records instead of the ES docs response
    def each(&block)
      records.each(&block)
    end

    # corresponding Envelopes for the search results
    def records
      @records ||= begin
        ids = hits.map(&:envelope_id)
        # get envelopes keeping them sorted by their search score
        Envelope.where(envelope_id: ids)
                .order_as_specified(envelope_id: ids)
      end
    end

    def total
      es_response['hits']['total']
    end

    def total_pages
      (total.to_f / options[:per_page]).ceil
    end

    def current_page
      options[:page]
    end

    def per_page
      options[:per_page]
    end

    def total_entries
      total
    end

    alias total_count total_entries

    def first_page?
      current_page == 1
    end

    def last_page?
      current_page == total_pages
    end

    # used only for compatibility with api-paginate's internal `paginate` method
    def page(*_args)
      self
    end

    # used only for compatibility with api-paginate's internal `paginate` method
    def per(*_args)
      self
    end
  end
end
