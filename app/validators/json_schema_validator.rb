# Validates that the same public key is used when updating/deleting an envelope
class JSONSchemaValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    errors = JSON::Validator.fully_validate(schema, record.processed_resource)

    if errors.any?
      record.errors.add :resource, "JSON Schema validation errors: #{errors}"
    end
  end

  private

  def schema
    File.read(File.expand_path("../../schemas/#{schema_file}", __FILE__))
  end

  def schema_file
    "#{record.community_name}.json"
  end
end
