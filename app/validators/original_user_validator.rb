# Validates that the same public key is used when updating/deleting a document
# TODO Also verify actual signature using the stored key
class OriginalUserValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    if (original_key_locations & updated_key_locations).empty?
      record.errors.add :user_envelope,
                        'Only the original user can update a resource'
    end
  end

  private

  def original_key_locations
    record.processed_envelope_was.dig('learning_registry_metadata',
                                      'digital_signature',
                                      'key_location')
  end

  def updated_key_locations
    record.lr_metadata.digital_signature.key_location
  end
end
