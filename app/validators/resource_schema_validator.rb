require 'json_schema_validator'

# Validates the encoded resource with the corresponding community schema-json
class ResourceSchemaValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    validator = JSONSchemaValidator.new(record.processed_resource, schema_name)
    validator.validate

    if validator.errors.try(:any?)
      errors = validator.error_messages
      record.errors.add :resource, "JSON Schema validation errors: #{errors}"
    end
  end

  def schema_name
    comm_name = record.community_name
    # credential_registry => credential_registry_schema_name
    custom_method = :"#{comm_name}_schema_name"
    respond_to?(custom_method) ? send(custom_method) : comm_name
  end

  def credential_registry_schema_name
    cti_type = record.processed_resource['@type']
    if cti_type
      "credential_registry/#{cti_type.gsub('cti:', '').underscore}"
    else
      record.errors.add :resource, 'Invalid resource @type'
    end
  end
end
