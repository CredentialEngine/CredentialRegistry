require 'schema_config'

module MetadataRegistry
  # Search service
  class Search
    attr_reader :params

    # Params:
    #   - params: [Hash] hash containing the search params
    def initialize(params)
      @params = params.with_indifferent_access.except!(:page, :per_page)
    end

    def run
      @query = Envelope.select_scope(include_deleted)

      # match by each method if they have valid entries
      query_methods.each { |method| send(:"search_#{method}") if send(method) }
      search_prepared_queries if community
      search_resource_fields

      @query
    end

    # filter methods
    def query_methods
      [:fts, :community, :type, :resource_type, :date_range]
    end

    def include_deleted
      @include_deleted ||= params.delete(:include_deleted)
    end

    # full-text-search param
    def fts
      @fts ||= params.delete(:fts)
    end

    # Get the community either from the `envelope_community` url param or
    # from the `community` query param
    def community
      @community ||= begin
        comm = params.delete(:envelope_community) || params.delete(:community)
        comm.present? ? comm.underscore : nil
      end
    end

    def type
      @type ||= params.delete(:type)
    end

    # get the resource_type from the config.
    def resource_type
      @resource_type ||= begin
        rtype = params.delete(:resource_type)
        if rtype.present? && resource_type_config.present?
          if resource_type_config.is_a?(String)
            # config: {"resource_type": "@type"}  => query: {"@type" => val}
            { resource_type_config => rtype }.to_json
          else
            resource_type_from_config(rtype)
          end
        end
      end
    end

    #  Get resource_type if the config is an object with mapped values
    #   given the config:
    #     {"resource_type": {
    #        "property": "@type", "values_map": {"abc:Bla": 'bla'}
    #     }}
    #
    #   The resulting query is:
    #      { value_from_property => inverted_values_map[val] }
    #   i.e., if val=bla:
    #      {"@type" => "abc:Bla"}
    def resource_type_from_config(rtype)
      inverted_values_map = resource_type_config['values_map'].invert
      value = inverted_values_map[rtype.singularize]
      { resource_type_config['property'] => value }.to_json
    end

    # get date_range hash. Accepts dates in natural-language description,
    # i.e: from: 'yesterday', until: '3 hours ago', are accepted values.
    def date_range
      @date_range ||= begin
        range = {
          from: Chronic.parse(params.delete(:from)),
          until: Chronic.parse(params.delete(:until))
        }.compact
        range.blank? ? nil : range
      end
    end

    # Search using the Searchable#search model method
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

    def search_prepared_queries
      prepared_queries = schema_config.try(:[], 'prepared_queries')
      prepared_queries.each do |key, query_tpl|
        term = params.delete(key)
        @query = @query.where(query_tpl.gsub('$term', '%s'), term) if term
      end if prepared_queries
    end

    # Build a jsonb query for all the remainig params.
    # The keys can be aliased, on this case we lookup the `aliases` config
    # The values can be any json piece to search using the 'contained' query
    def search_resource_fields
      params.each do |key, val|
        prop = schema_config.dig('aliases', key) || key
        json = { prop => parsed_value(val) }.to_json
        @query = @query.where('processed_resource @> ?', json)
      end
    end

    def schema_config
      @schema_config ||= SchemaConfig.new(community).config
    end

    def resource_type_config
      @rtype_mapping ||= schema_config.try(:[], 'resource_type')
    end

    def parsed_value(val)
      JSON.parse(val)
    rescue JSON::ParserError
      val
    end
  end
end
