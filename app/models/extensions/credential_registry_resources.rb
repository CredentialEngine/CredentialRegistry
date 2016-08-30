require 'active_support/concern'

# CredentialRegistry specific behavior for resource envelopes
module CredentialRegistryResources
  extend ActiveSupport::Concern

  included do
    scope :with_ctid, (lambda do |ctid|
      where('processed_resource @> ?', { 'ctdl:ctid' => ctid }.to_json)
    end)

    validate :unique_ctid, if: :credential_registry?

    def unique_ctid
      if Envelope.in_community('credential_registry')
                 .where.not(envelope_id: envelope_id)
                 .with_ctid(processed_resource['ctdl:ctid'])
                 .exists?
        errors.add :resource, 'CTID must be unique'
      end
    end

    def credential_registry?
      community_name == 'credential_registry'
    end

    def self.generate_ctid
      "urn:guid:#{SecureRandom.uuid}"
    end
  end
end
