# Validates that the same public key is used when updating/deleting an envelope
class OriginalUserValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    if locations_mismatch? || keys_differ?
      record.errors.add :resource, 'can only be updated by the original user'
    end
  end

  private

  def locations_mismatch?
    (original_key_locations & updated_key_locations).empty?
  end

  def keys_differ?
    record.resource_public_key_changed?
  end

  def original_key_locations
    record.processed_resource_was.dig('learning_registry_metadata',
                                      'digital_signature',
                                      'key_location')
  end

  def updated_key_locations
    record.lr_metadata.digital_signature.key_location
  end
end
