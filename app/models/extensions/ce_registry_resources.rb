require 'active_support/concern'

# CE/Registry specific behavior for resource envelopes
module CERegistryResources
  extend ActiveSupport::Concern

  included do
    scope :with_ctid, (lambda do |ctid|
      where('processed_resource @> ?', { 'ctdl:ctid' => ctid }.to_json)
    end)

    validate :unique_ctid, if: :ce_registry?

    def unique_ctid
      if Envelope.in_community('ce_registry')
                 .where.not(envelope_id: envelope_id)
                 .with_ctid(processed_resource['ctdl:ctid'])
                 .exists?
        errors.add :resource, 'CTID must be unique'
      end
    end

    def ce_registry?
      community_name =~ /ce_registry/
    end

    def self.generate_ctid
      "urn:ctid:#{SecureRandom.uuid}"
    end
  end
end
