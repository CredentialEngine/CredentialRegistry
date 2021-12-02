# Fetches subresources from the graphs of envelopes with the given CTIDs
class FetchGraphResources
  def self.call(ctids)
    Envelope
      .not_deleted
      .joins("CROSS JOIN LATERAL jsonb_array_elements(processed_resource->'@graph') AS graph(resource)")
      .where(envelope_ceterms_ctid: ctids)
      .where("graph.resource->>'ceterms:ctid' NOT IN (?)", ctids)
      .pluck('graph.resource')
      .map { |r| JSON(r) }
  end
end
