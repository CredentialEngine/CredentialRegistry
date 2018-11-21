require 'base_interactor'
require 'envelope_resource'

# Extracts all the objects out of an envelope that has a graph.
class ExtractEnvelopeResources < BaseInteractor
  def call(params)
    envelope = params[:envelope]
    resource = envelope.processed_resource

    EnvelopeResource.transaction do
      # Destroy previous objects if this is an update
      EnvelopeResource.where(envelope_id: envelope).destroy_all

      if (graph = resource['@graph']).present?
        graph.each { |obj| store_object(envelope, obj) }
      else
        store_object(envelope, resource)
      end

      true
    end
  end

  private

  def store_object(envelope, object)
    obj_id = object[envelope.id_field]

    # Skip blank IDs, blank @types, bnodes
    return if obj_id.blank? || obj_id.start_with?('_:') || object['@type'].blank?

    resource = EnvelopeResource.new(
      resource_id: obj_id.downcase,
      envelope_id: envelope.id,
      envelope_type: envelope.envelope_type,
      updated_at: envelope.updated_at,
      processed_resource: object
    )
    resource.set_fts_attrs
    resource.save!
  end
end
