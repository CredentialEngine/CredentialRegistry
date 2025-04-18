class FetchEnvelopeResource # rubocop:todo Style/Documentation
  BNODE_ID_REGEX = '(?<=")_:[^"]+(?=")'.freeze

  attr_reader :envelope_community, :resource_id

  delegate :connection, to: ActiveRecord::Base
  delegate :quote, to: :connection

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
        WHERE (envelope_resources.resource_id = #{quote(resource_id)}
        OR envelope_resources.resource_id LIKE #{quote("%/#{resource_id}")})
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
          WHERE resource_id LIKE #{quote("%#{resource_id}")}
        ),
        '{@included}',
        (
          SELECT COALESCE(json_agg(processed_resource), '[]'::json)
          FROM resources
          WHERE resource_id NOT LIKE #{quote("%#{resource_id}")}
        )::jsonb,
        (SELECT COUNT(*) FROM resources) > 1
      ) AS resource
    SQL
  end

  def resource
    @resource ||= begin
      result = connection.execute(query)

      result.type_map = PG::BasicTypeMapForResults.new(
        connection.raw_connection
      )

      resource = result.first.fetch('resource')
      return resource if resource # rubocop:todo Lint/NoReturnInBeginEndBlocks

      raise ActiveRecord::RecordNotFound, "Couldn't find Resource"
    end
  end
end
