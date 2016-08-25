module MetadataRegistry
  # Search service abstraction class
  class Search
    attr_reader :params

    def initialize(params)
      @params = params.with_indifferent_access
    end

    def run
      @query = Envelope.all

      [:fts, :community, :type, :resource_type, :date_range].each do |method|
        send(:"search_#{method}") if send(method)
      end

      @query
    end

    def fts
      params[:fts]
    end

    def community
      @community ||= begin
        comm = params[:envelope_community] || params[:community]
        comm.present? ? comm.underscore : nil
      end
    end

    def type
      @type ||= params[:type]
    end

    def resource_type
      # TODO: review this, doesn't seem right, should come from the config
      @type ||= begin
        if params[:resource_type].present?
          value = "ctdl:#{params[:resource_type].singularize.classify}"
          { '@type': value }.to_json
        end
      end
    end

    def date_range
      @date_range ||= begin
        range = { from: params[:from], until: params[:until] }.compact
        range.blank? ? nil : range
      end
    end

    def search_fts
      @query = @query.fts_search(fts)
    end

    def search_community
      @query = @query.in_community(community)
    end

    def search_type
      @query = @query.where(envelope_type: type)
    end

    def search_resource_type
      @query = @query.where('processed_resource @> ?', resource_type)
    end

    def search_date_range
      # TODO: implement-me
      @query
    end
  end
end
