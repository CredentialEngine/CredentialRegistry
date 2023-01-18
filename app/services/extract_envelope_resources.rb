require 'base_interactor'
require 'envelope_resource'

# Extracts all the objects out of an envelope that has a graph.
class ExtractEnvelopeResources < BaseInteractor
  attr_reader :envelope

  def call(params)
    @envelope = params[:envelope]
    resource = envelope.processed_resource

    resources =
      if (graph = resource['@graph']).present?
        graph.map { |resource| build_resource(resource) }
      else
        [build_resource(resource)]
      end.compact

    resource_ids = resources.map(&:resource_id)

    EnvelopeResource.transaction do
      EnvelopeResource.bulk_import(resources, on_duplicate_key_update: :all)

      if resources.any?
        envelope
          .envelope_resources
          .where.not(resource_id: resource_ids)
          .delete_all
      end
    end
  end

  private

  def build_resource(object)
    obj_id = object[envelope.id_field] || object['@id']

    # Skip blank IDs, blank @types
    return if obj_id.blank? || object['@type'].blank?

    resource = envelope.envelope_resources.find_or_initialize_by(
      resource_id: obj_id.downcase
    )

    resource.envelope_type = envelope.envelope_type
    resource.processed_resource = object
    resource.updated_at = envelope.updated_at
    resource.set_fts_attrs
    resource
  end
end
