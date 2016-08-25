require 'schema_config'

module MetadataRegistry
  # Search service abstraction class
  class Search
    attr_reader :params

    def initialize(params)
      @params = params.with_indifferent_access
    end

    def run
      @query = Envelope.all
      query_methods.each { |method| send(:"search_#{method}") if send(method) }

      @query
    end

    def query_methods
      [:fts, :community, :type, :resource_type, :date_range, :identifier]
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
      # TODO: review this, should come from the config
      @resource_type ||= begin
        if params[:resource_type].present?
          value = "ctdl:#{params[:resource_type].singularize.classify}"
          { '@type': value }.to_json
        end
      end
    end

    def date_range
      @date_range ||= begin
        range = {
          from: Chronic.parse(params[:from]),
          until: Chronic.parse(params[:until])
        }.compact
        range.blank? ? nil : range
      end
    end

    def identifier
      @identifier ||= begin
        return nil unless community

        cfg = SchemaConfig.new(community).config.try(:[], 'identifier')
        if cfg.is_a?(String)
          build_identifier_from_string(cfg)
        elsif cfg.is_a?(Hash)
          build_identifier_from_hash(cfg)
        end
      end
    end

    def build_identifier_from_string(cfg)
      identifier = params.slice(*['identifier', cfg]).values.first
      identifier ? { cfg => identifier }.to_json : nil
    end

    def build_identifier_from_hash(cfg)
      keys = ['identifier', cfg['property'], cfg['alias']]
      identifier = params.slice(*keys).values.first
      identifier ? { cfg['property'] => identifier }.to_json : nil
    end

    def search_fts
      @query = @query.search(fts)
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
      from = date_range[:from]
      till = date_range[:until]
      @query = @query.where('envelopes.updated_at >= ?', from) if from
      @query = @query.where('envelopes.updated_at <= ?', till) if till
    end

    def search_identifier
      @query = @query.where('processed_resource @> ?', identifier)
    end
  end
end
