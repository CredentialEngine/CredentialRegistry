require 'ctdl_query'
require 'fetch_graph_resources'
require 'query_log'

class RunCtdlQuery
  def self.call(
    payload,
    debug: false,
    envelope_community:,
    include_description_set_resources: false,
    include_description_sets: false,
    include_graph_data: false,
    include_results_metadata: false,
    log: false,
    order_by: nil,
    per_branch_limit: nil,
    skip: nil,
    take: nil
  )
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
            skip: skip,
            take: take
          }
        )
      end

    count_query = CtdlQuery.new(
      payload,
      envelope_community: envelope_community,
      project: 'COUNT(*) AS count'
    )

    data_query = CtdlQuery.new(
      payload,
      envelope_community: envelope_community,
      order_by: order_by,
      project: %w["@id" "ceterms:ctid" payload],
      skip: skip,
      take: take,
      with_metadata: include_results_metadata
    )

    rows = data_query.execute

    result = {
      data: rows.map { |r| JSON(r.fetch('payload')) },
      total: count_query.execute.first.fetch('count')
    }

    ctids = rows.map { |r| r.fetch('ceterms:ctid') }.compact

    result.merge!(sql: data_query.to_sql) if debug

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
      result.merge!(
        description_set_resources: FetchGraphResources.call(
          ctids,
          envelope_community: envelope_community
        )
      )
    end

    if include_results_metadata
      result.merge!(
        results_metadata: rows.map do |r|
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
      )
    end

    query_log&.update(query: data_query.to_sql)
    query_log&.complete(result)
    OpenStruct.new(result: result, status: 200)
  rescue => e
    query_log&.fail(e.message)
    Airbrake.notify(e, query: payload)

    OpenStruct.new(
      result: { error: e.message },
      status: 500
    )
  end
end
