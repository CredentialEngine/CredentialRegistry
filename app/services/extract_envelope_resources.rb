require 'base_interactor'
require 'envelope_resource'

# Extracts all the objects out of an envelope that has a graph.
class ExtractEnvelopeResources < BaseInteractor
  attr_reader :envelope

  def call(params)
    @envelope = params[:envelope]
    resource = envelope.processed_resource

    EnvelopeResource.transaction do
      # Destroy previous objects if this is an update
      EnvelopeResource.where(envelope_id: envelope).delete_all

      resources =
        if (graph = resource['@graph']).present?
          graph.map { |resource| build_resource(resource) }
        else
          [build_resource(resource)]
        end

      EnvelopeResource.bulk_import(resources.compact)
    end
  end

  private

  def build_resource(object)
    obj_id = object[envelope.id_field] || object['@id']

    # Skip blank IDs, blank @types
    return if obj_id.blank? || object['@type'].blank?

    resource = envelope.envelope_resources.new(
      resource_id: obj_id.downcase,
      envelope_type: envelope.envelope_type,
      updated_at: envelope.updated_at,
      processed_resource: object
    )

    resource.set_fts_attrs
    resource
  end
end
