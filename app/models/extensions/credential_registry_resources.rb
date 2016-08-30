require 'active_support/concern'

# CredentialRegistry specific behavior for resource envelopes
module CredentialRegistryResources
  extend ActiveSupport::Concern

  included do
    def self.generate_ctid
      "urn:guid:#{SecureRandom.uuid}"
    end
  end
end
