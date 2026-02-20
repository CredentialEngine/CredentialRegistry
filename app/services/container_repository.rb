# Manages subresources of a container
class ContainerRepository
  attr_reader :envelope

  delegate :processed_resource, to: :envelope

  def initialize(envelope)
    @envelope = envelope
  end

  def add_member_uri(uris)
    existing_uris = container['ceterms:hasMember'] || []
    container['ceterms:hasMember'] = (existing_uris + Array.wrap(uris)).uniq
    update_envelope!
  end

  def remove_member_uris(uris)
    existing_uris = container['ceterms:hasMember'] || []
    container['ceterms:hasMember'] = existing_uris - Array.wrap(uris)
    update_envelope!
  end

  def container
    @container ||= graph.find { it['@type'] == 'ceterms:Collection' }
  end

  def graph
    @graph ||= processed_resource['@graph']
  end

  def update_envelope!
    envelope.update!(processed_resource:)
    changed = envelope.previous_changes.any?
    ExtractEnvelopeResourcesJob.perform_later(envelope.id) if changed
    changed
  end
end
