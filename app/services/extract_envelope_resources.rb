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
    id_field = envelope.id_field
    obj_id = object[id_field]
    return if obj_id.blank? || obj_id.start_with?('_:') || object['@type'].blank?

    envelope_resource = EnvelopeResource.find_or_initialize_by(
      resource_id: obj_id.downcase
    )
    envelope_resource.assign_attributes(
      envelope_id: envelope.id,
      processed_resource: object,
      envelope_type: envelope.envelope_type,
      updated_at: envelope.updated_at
    )
    envelope_resource.set_fts_attrs
    raise ActiveRecord::Rollback unless envelope_resource.save
  end
end
