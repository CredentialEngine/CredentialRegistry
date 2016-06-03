require 'json_schema_validator'

# validates a params request against the envelope json-schema
class EnvelopeSchemaValidator < JSONSchemaValidator
  def schema_file
    File.expand_path('../../schemas/envelope.json', __FILE__)
  end
end
