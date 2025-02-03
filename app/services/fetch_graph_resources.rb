# Fetches subresources from the graphs of envelopes with the given CTIDs
class FetchGraphResources
  def self.call(ctids, envelope_community:)
    relation = Envelope
               .not_deleted
               # rubocop:todo Layout/LineLength
               .joins("CROSS JOIN LATERAL jsonb_array_elements(processed_resource->'@graph') AS graph(resource)")
               # rubocop:enable Layout/LineLength
               .where(envelope_ceterms_ctid: ctids)

    relation = relation
               .where("graph.resource->'ceterms:ctid' IS NULL")
               .or(relation.where("graph.resource->>'ceterms:ctid' NOT IN (?)", ctids))

    relation = relation.where(envelope_community_id: envelope_community.id) if envelope_community

    relation.pluck('graph.resource').map { |r| JSON(r) }
  end
end
