require 'active_support/concern'

# json-schema specific behavior for json-schema envelopes
module JsonSchemaResources
  extend ActiveSupport::Concern

  included do
    scope :schemas, (lambda do
      unscoped.where(envelope_type: envelope_types['json_schema'])
    end)

    scope :with_schema_name, (lambda do |name|
      where('processed_resource @> ?', { 'name' => name }.to_json)
    end)

    validate :unique_json_schema_name, if: :json_schema?

    def unique_json_schema_name
      if Envelope.schemas
                 .where.not(envelope_id: envelope_id)
                 .with_schema_name(processed_resource['name'])
                 .exists?
        errors.add :resource, 'Schema name must be unique'
      end
    end
  end
end
