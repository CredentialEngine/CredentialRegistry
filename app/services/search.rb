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
      @resource_type ||= begin
        rtype = params.delete(:resource_type)
        if rtype.present?
          values_map = resource_type_config.try(:[], 'values_map')
          return nil if values_map.blank?

          value = values_map.invert[rtype.singularize]
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
      @aliases ||= schema_config.try(:[], 'aliases')
    end

    def resource_type_config
      @rtype_mapping ||= schema_config.try(:[], 'resource_type')
    end

    def schema_config
      @schema_config ||= SchemaConfig.new(community).config
    end

    def parsed_value(val)
      JSON.parse(val)
    rescue
      val
    end
  end
end
