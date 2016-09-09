require 'helpers/shared_helpers'

module API
  module V1
    # CredentialRegistry-specific api endpoints
    class CredentialRegistry < Grape::API
      helpers SharedHelpers

      route_param :envelope_community do
        before_validation do
          if params[:envelope_community].underscore != 'credential_registry'
            msg = 'envelope_community does not have a valid value'
            error!({ errors: msg }, 400)
          end
        end

        desc 'Generate a CredentialRegistry CTID'
        get 'ctid' do
          { ctid: Envelope.generate_ctid }
        end
      end
    end
  end
end
