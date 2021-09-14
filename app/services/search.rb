require 'envelope_resource'

module MetadataRegistry
  # Search service
  class Search
    attr_reader :params

    # Params:
    #   - params: [Hash] hash containing the search params
    def initialize(params)
      @params = params
        .with_indifferent_access
        .except(:metadata_only, :page, :per_page)

      @sort_by = @params.delete(:sort_by)
      @sort_order = @params.delete(:sort_order)
    end

    def run
      @query = EnvelopeResource.select_scope(include_deleted).joins(:envelope)

      # match by each method if they have valid entries
      query_methods.each { |method| send(:"search_#{method}") if send(method) }
      search_prepared_queries if community
      search_resource_fields
      sort_results

      @query.includes(envelope: %i[organization publishing_organization])
    end

    # filter methods
    def query_methods
      %i[
        fts community type resource_type date_range envelope_ceterms_ctid
        envelope_id envelope_ctdl_type owned_by published_by with_bnodes
      ]
    end

    def sort_columns
      %w[created_at updated_at]
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
        rtype.present? ? rtype.singularize : nil
      end
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

    def envelope_ceterms_ctid
      @envelope_ceterms_ctid ||= extract_param(:envelope_ceterms_ctid)
    end

    def envelope_id
      @envelope_id ||= extract_param(:envelope_id)
    end

    def envelope_ctdl_type
      @envelope_ctdl_type ||= extract_param(:envelope_ctdl_type)
    end

    def owned_by
      @owned_by ||= extract_param(:owned_by)
    end

    def published_by
      @published_by ||= extract_param(:published_by)
    end

    def with_bnodes
      @with_bnodes ||= extract_param(:with_bnodes)&.first || 'false'
    end

    # Search using the Searchable#search model method
    def search_fts
      @query = @query.search(fts)
    end

    def search_community
      @query = @query.in_community(community)
    end

    def search_type
      @query = @query.where(envelope_type: EnvelopeResource.envelope_types[type])
    end

    def search_resource_type
      @query = @query.where(resource_type: resource_type)
    end

    def search_date_range
      from = date_range[:from]
      till = date_range[:until]
      @query = @query.where('envelopes.updated_at >= ?', from) if from
      @query = @query.where('envelopes.updated_at <= ?', till) if till
    end

    def search_prepared_queries
      prepared_queries = config.try(:[], 'prepared_queries')
      prepared_queries&.each do |key, query_tpl|
        term = params.delete(key)
        next if term.blank?
        @query = @query.where(query_tpl.gsub('$term', '%s'), term)
      end
    end

    # Build a jsonb query for all the remainig params.
    # The keys can be aliased, on this case we lookup the `aliases` config
    # The values can be any json piece to search using the 'contained' query
    def search_resource_fields
      params.each do |key, val|
        prop = config.dig('aliases', key) || key
        json = { prop => parsed_value(val) }.to_json
        q = 'envelope_resources.processed_resource @> ?'
        @query = @query.where(q, json)
      end
    end

    def search_envelope_ceterms_ctid
      @query = @query
        .where(envelopes: { envelope_ceterms_ctid: envelope_ceterms_ctid })
    end

    def search_envelope_id
      @query = @query
        .where(envelopes: { envelope_id: envelope_id })
    end

    def search_envelope_ctdl_type
      @query = @query
        .where(envelopes: { envelope_ctdl_type: envelope_ctdl_type })
    end

    def search_owned_by
      envelope_ids = Envelope
        .joins(:organization)
        .where(organizations: { _ctid: owned_by })
        .select(:id)

      @query = @query.where(envelopes: { id: envelope_ids })
    end

    def search_published_by
      envelope_ids = Envelope
        .joins(:publishing_organization)
        .where(organizations: { _ctid: published_by })
        .select(:id)

      @query = @query.where(envelopes: { id: envelope_ids })
    end

    def search_with_bnodes
      @query =
        case with_bnodes
        when 'only' then @query.where("resource_id LIKE '_:%'")
        when 'true' then @query
        else @query.where("resource_id NOT LIKE '_:%'")
        end
    end

    def sort_results
      sort_by = sort_columns.include?(@sort_by) ? @sort_by : 'updated_at'
      sort_order = %w[asc desc].include?(@sort_order) ? @sort_order : 'desc'
      @query.order!(sort_by => sort_order)
    end

    def config
      @config ||= EnvelopeCommunity.find_by(name: community)&.config
    end

    def parsed_value(val)
      JSON.parse(val)
    rescue JSON::ParserError
      val
    end

    def extract_param(key)
      (params.delete(key) || '').split(',').presence
    end
  end
end
