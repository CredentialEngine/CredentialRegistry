require 'schema_config'

module MetadataRegistry
  # Search service abstraction class
  class Search
    attr_reader :params

    def initialize(params)
      @params = params.with_indifferent_access.except!(:page, :per_page)
    end

    def run
      @query = Envelope.all
      query_methods.each { |method| send(:"search_#{method}") if send(method) }
      search_resource_fields

      @query
    end

    def query_methods
      [:fts, :community, :type, :resource_type, :date_range]
    end

    def fts
      @fts ||= params.delete(:fts)
    end

    def community
      @community ||= begin
        comm = params.delete(:envelope_community) || params.delete(:community)
        comm.present? ? comm.underscore : nil
      end
    end

    def type
      @type ||= params.delete(:type)
    end

    def resource_type
      # TODO: review this, should come from the config
      @resource_type ||= begin
        rtype = params.delete(:resource_type)
        if rtype.present? && community && community == 'credential_registry'
          value = "ctdl:#{rtype.singularize.classify}"
          { '@type': value }.to_json
        end
      end
    end

    def date_range
      @date_range ||= begin
        range = {
          from: Chronic.parse(params.delete(:from)),
          until: Chronic.parse(params.delete(:until))
        }.compact
        range.blank? ? nil : range
      end
    end

    def search_fts
      @query = @query.search(fts)
    end

    def search_community
      @query = @query.in_community(community)
    end

    def search_type
      @query = @query.where(envelope_type: Envelope.envelope_types[type])
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

    def search_resource_fields
      params.each do |key, val|
        next if val.blank?

        prop = aliases.try(:[], key) || key
        json = { prop => parsed_value(val) }.to_json
        @query = @query.where('processed_resource @> ?', json)
      end
    end

    def aliases
      @aliases ||= SchemaConfig.new(community).config.try(:[], 'aliases')
    end

    def parsed_value(val)
      JSON.parse(val)
    rescue
      val
    end
  end
end
