require 'fetch_graph_resources'

# Fetches description set data for the given CTIDs
class FetchDescriptionSetData
  # rubocop:todo Metrics/PerceivedComplexity
  # rubocop:todo Metrics/MethodLength
  # rubocop:todo Metrics/AbcSize
  # rubocop:todo Metrics/ParameterLists
  def self.call( # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists, Metrics/PerceivedComplexity
    ctids,
    include_graph_data: false,
    include_resources: false,
    include_results_metadata: false,
    envelope_community: nil,
    path_contains: nil,
    path_exact: nil,
    per_branch_limit: nil
  )
    # rubocop:enable Metrics/ParameterLists
    description_sets = DescriptionSet
                       .where(ceterms_ctid: ctids)
                       .select(:ceterms_ctid, :path)
                       .select('cardinality(uris) total')
                       .order(:ceterms_ctid, Arel.sql('path COLLATE "C"'))

    description_sets.where!(envelope_community: envelope_community) if envelope_community

    if path_exact.present?
      description_sets.where!('LOWER(path) = ?', path_exact.downcase)
    elsif path_contains.present?
      description_sets.where!("path ILIKE '%#{path_contains}%'")
    end

    description_sets =
      if per_branch_limit
        description_sets.select("uris[1:#{per_branch_limit}] uris")
      else
        description_sets.select(:uris)
      end

    description_set_groups = description_sets
                             .group_by(&:ceterms_ctid)
                             .map do |group|
      OpenStruct.new(ctid: group.first, description_set: group.last)
    end

    resource_relation = EnvelopeResource
                        .not_deleted
                        .where(resource_id: ctids)
                        .select(:processed_resource, :resource_id)

    if envelope_community
      resource_relation = resource_relation
                          .joins(:envelope)
                          .where(envelopes: { envelope_community_id: envelope_community.id })
    end

    if include_results_metadata
      resource_relation = resource_relation
                          .joins(:envelope)
                          .left_joins(envelope: %i[organization publishing_organization])
                          .select(
                            'envelopes.created_at, ' \
                            'envelopes.updated_at, ' \
                            'organizations._ctid owned_by, ' \
                            'publishing_organizations_envelopes._ctid published_by'
                          )
    end

    resources = []
    results_metadata = [] if include_results_metadata

    resource_relation.sort_by { |r| ctids.find_index(r.resource_id) }.each do |resource|
      resources << resource.processed_resource
      next unless include_results_metadata

      results_metadata << {
        resource_uri: resource.resource_id,
        created_at: resource.created_at,
        updated_at: resource.updated_at,
        owned_by: resource.owned_by,
        published_by: resource.published_by
      }
    end

    graph_resources =
      if include_graph_data
        FetchGraphResources.call(ctids, envelope_community: envelope_community)
      end

    if include_resources
      ids = description_sets.map(&:uris).flatten.uniq.map do |uri|
        id = uri.split('/').last
        next id unless uri.starts_with?('https://credreg.net/bnodes/')

        "_:#{id}"
      end

      subresource_relation = EnvelopeResource.not_deleted.where(resource_id: ids)

      if envelope_community
        subresource_relation = subresource_relation
                               .joins(:envelope)
                               .where(envelopes: { envelope_community_id: envelope_community.id })
      end

      subresources = subresource_relation.pluck(:processed_resource)
    end

    subresources =
      ([*graph_resources, *subresources].uniq if include_graph_data || include_resources)

    OpenStruct.new(
      description_set_groups:,
      resources:,
      subresources:,
      results_metadata:
    )
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity
end
