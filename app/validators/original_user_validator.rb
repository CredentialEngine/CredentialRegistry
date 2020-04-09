require 'administrative_account'

# Validates that the same public key is used when updating/deleting an envelope
class OriginalUserValidator < ActiveModel::Validator
  attr_reader :record

  def validate(record)
    @record = record

    return unless (locations_mismatch? || keys_differ?) && !administrative_account?

    record.errors.add :resource, 'can only be updated by the original user. ' \
                                 'There is a public key or key locations mismatch.'
  end

  private

  def locations_mismatch?
    return false unless record.processed_resource['registry_metadata']

    (original_key_locations & updated_key_locations).empty?
  end

  def keys_differ?
    cleaned_key(record.resource_public_key) != cleaned_key(record.resource_public_key_was)
  end

  def administrative_account?
    return true if record.publisher&.super_publisher?

    AdministrativeAccount.exists?(public_key: record.resource_public_key)
  end

  def original_key_locations
    record.processed_resource_was.dig('registry_metadata',
                                      'digital_signature',
                                      'key_location')
  end

  def updated_key_locations
    # record.lr_metadata.digital_signature.key_location
    record.processed_resource.dig('registry_metadata',
                                  'digital_signature',
                                  'key_location')
  end

  def cleaned_key(key)
    key.strip.gsub(/\n$/, '')
  end
end
