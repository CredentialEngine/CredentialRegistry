require 'base_interactor'
require 'envelope_resource'
require 'envelope_resource_sync_event'

# Extracts all the objects out of an envelope that has a graph.
class ExtractEnvelopeResources < BaseInteractor
  attr_reader :envelope

  # rubocop:todo Metrics/MethodLength
  def call(params) # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @envelope = params[:envelope]
    resource = envelope.processed_resource

    envelope.with_lock do
      existing_resource_ids = envelope.envelope_resources.pluck(:resource_id)
      resources =
        if (graph = resource['@graph']).present?
          graph.map { |resource| build_resource(resource) }
        else
          [build_resource(resource)]
        end.compact

      resource_ids = resources.map(&:resource_id)
      deleted_resource_ids = existing_resource_ids - resource_ids

      EnvelopeResource.transaction do
        EnvelopeResource.bulk_import(resources, on_duplicate_key_update: :all)

        if resources.any?
          envelope
            .envelope_resources
            .where.not(resource_id: resource_ids)
            .delete_all
        end

        record_sync_events(resource_ids, deleted_resource_ids)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def build_resource(object) # rubocop:todo Metrics/AbcSize
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

  def record_sync_events(resource_ids, deleted_resource_ids)
    event_rows = []
    now = Time.current

    resource_ids.each do |resource_id|
      event_rows << sync_event_row(resource_id, :upsert, now)
    end

    deleted_resource_ids.each do |resource_id|
      event_rows << sync_event_row(resource_id, :delete, now)
    end

    EnvelopeResourceSyncEvent.insert_all!(event_rows) if event_rows.any?
  end

  def sync_event_row(resource_id, action, now)
    {
      envelope_community_id: envelope.envelope_community_id,
      resource_id: resource_id,
      action: EnvelopeResourceSyncEvent::ACTIONS.fetch(action),
      created_at: now,
      updated_at: now
    }
  end
end
