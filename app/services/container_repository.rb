# Manages subresources of a container
class ContainerRepository
  attr_reader :envelope

  delegate :processed_resource, to: :envelope

  def initialize(envelope)
    @envelope = envelope
  end

  def add(subresource)
    container['ceterms:hasMember'] ||= []
    subresource_id = subresource['@id']

    unless container['ceterms:hasMember'].include?(subresource_id)
      container['ceterms:hasMember'] << subresource_id
    end

    graph << subresource unless graph.find { it['@id'] == subresource_id }
    update_envelope!
  end

  def remove(subresource_ctid)
    subresource = graph.find { |obj| obj['ceterms:ctid'] == subresource_ctid }
    return false unless subresource

    subresource_id = subresource['@id']
    container['ceterms:hasMember']&.delete(subresource_id)
    graph.reject! { |obj| obj['@id'] == subresource_id }
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
