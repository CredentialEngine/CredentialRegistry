require 'ctdl_query'
require 'fetch_graph_resources'
require 'query_log'

class RunCtdlQuery # rubocop:todo Style/Documentation
  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  # rubocop:todo Metrics/ParameterLists
  def self.call( # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists, Metrics/PerceivedComplexity
    payload,
    envelope_community:, debug: false,
    include_description_set_resources: false,
    include_description_sets: false,
    include_graph_data: false,
    include_results_metadata: false,
    log: false,
    order_by: nil,
    per_branch_limit: nil,
    provisional: nil,
    skip: nil,
    take: nil
  )
    # rubocop:enable Metrics/ParameterLists
    query_log =
      if log
        QueryLog.start(
          ctdl: payload,
          engine: 'ctdl',
          options: {
            envelope_community_id: envelope_community.id,
            include_description_set_resources: include_description_set_resources,
            include_description_sets: include_description_sets,
            include_graph_data: include_graph_data,
            include_results_metadata: include_results_metadata,
            order_by: order_by,
            per_branch_limit: per_branch_limit,
            provisional:,
            skip: skip,
            take: take
          }
        )
      end

    query = CtdlQuery.new(
      payload,
      envelope_community: envelope_community,
      order_by: order_by,
      project: %i[@id ceterms:ctid payload],
      provisional:,
      skip: skip,
      take: take,
      with_metadata: include_results_metadata
    )

    rows = query.rows

    result = {
      data: rows.map { JSON(it.fetch('payload')) },
      total: query.total_count
    }

    ctids = rows.filter_map { |r| r.fetch('ceterms:ctid') }
    result[:sql] = query.to_sql if debug

    if include_description_set_resources || include_description_sets
      description_set_data = FetchDescriptionSetData.call(
        ctids,
        envelope_community: envelope_community,
        include_graph_data: include_graph_data,
        include_resources: include_description_set_resources,
        per_branch_limit: per_branch_limit
      )

      entity = API::Entities::DescriptionSetData.represent(description_set_data)
      result.merge!(entity.as_json)
    elsif include_graph_data
      result[:description_set_resources] = FetchGraphResources.call(
        ctids,
        envelope_community: envelope_community
      )
    end

    if include_results_metadata
      result[:results_metadata] = rows.map do |r|
        {
          'resource_uri' => r.fetch('@id'),
          **r.slice(
            'search:recordCreated',
            'search:recordOwnedBy',
            'search:recordPublishedBy',
            'search:resourcePublishType',
            'search:recordUpdated'
          )
        }
      end
    end

    query_log&.update(query: query.to_sql)
    query_log&.complete(result)
    OpenStruct.new(result: result, status: 200)
  rescue StandardError => e
    query_log&.fail(e.message)
    Airbrake.notify(e, query: payload)

    OpenStruct.new(
      result: { error: e.message },
      status: 500
    )
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
end
