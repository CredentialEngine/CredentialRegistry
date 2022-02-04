require 'active_support/concern'

# CE/Registry specific behavior for resource envelopes
module CERegistryResources
  extend ActiveSupport::Concern

  included do
    validate :unique_ctid, if: :ce_registry?, unless: :deleted?

    def unique_ctid
      if Envelope.not_deleted
                 .in_community('ce_registry')
                 .where.not(envelope_id: envelope_id)
                 .where(envelope_ceterms_ctid: processed_resource_ctid)
                 .exists?
        errors.add :resource, 'CTID must be unique'
      end
    end

    def ce_registry?
      envelope_community.name =~ /ce_registry/
    end

    def self.generate_ctid
      "urn:ctid:#{SecureRandom.uuid}"
    end
  end
end
