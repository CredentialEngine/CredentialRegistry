class FetchEnvelopeResource
  BNODE_ID_REGEX = '(?<=")_:[^"]+(?=")'.freeze

  attr_reader :envelope_community, :resource_id

  def initialize(envelope_community:, resource_id:)
    @envelope_community = envelope_community
    @resource_id = resource_id&.downcase
  end

  def query
    <<~SQL
      WITH RECURSIVE resources AS (
        SELECT
          envelope_resources.resource_id,
          envelope_resources.processed_resource,
          envelopes.processed_resource->'@context' context,
          array[envelope_resources.resource_id]::text[] as path
        FROM  envelope_resources
        INNER JOIN envelopes
        ON envelopes.id = envelope_resources.envelope_id
        WHERE envelope_resources.resource_id LIKE '%#{resource_id}'
        AND envelopes.deleted_at IS NULL
        AND envelopes.envelope_community_id = #{envelope_community.id}
        UNION
        SELECT
          envelope_resources.resource_id,
          envelope_resources.processed_resource,
          '{}'::jsonb context,
          path || envelope_resources.resource_id
        FROM envelope_resources
        INNER JOIN envelopes
        ON envelopes.id = envelope_resources.envelope_id
        INNER JOIN (
          SELECT
            unnest(REGEXP_MATCHES(processed_resource::TEXT, '#{BNODE_ID_REGEX}', 'g')) resource_id,
            path
          FROM resources
        ) bnodes
        ON envelope_resources.resource_id = bnodes.resource_id
        WHERE NOT envelope_resources.resource_id = ANY(bnodes.path)
        AND envelopes.deleted_at IS NULL
        AND envelopes.envelope_community_id = #{envelope_community.id}
      )
      SELECT jsonb_set(
        (
          SELECT processed_resource || jsonb_build_object('@context', context)
          FROM resources
          WHERE resource_id LIKE '%#{resource_id}'
        ),
        '{@included}',
        (
          SELECT COALESCE(json_agg(processed_resource), '[]'::json)
          FROM resources
          WHERE resource_id NOT LIKE '%#{resource_id}'
        )::jsonb,
        (SELECT COUNT(*) FROM resources) > 1
      ) AS resource
    SQL
  end

  def resource
    @resource ||= begin
      connection = ActiveRecord::Base.connection
      result = connection.execute(query)

      result.type_map = PG::BasicTypeMapForResults.new(
        connection.raw_connection
      )

      result.first.fetch('resource')
    end
  end
end
