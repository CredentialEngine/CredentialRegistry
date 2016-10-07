require 'helpers/shared_helpers'

module API
  module V1
    # CE/Registry-specific api endpoints
    class CERegistry < Grape::API
      helpers SharedHelpers

      route_param :envelope_community do
        before_validation do
          unless params[:envelope_community].underscore =~ /ce_registry/
            msg = 'envelope_community does not have a valid value'
            error!({ errors: msg }, 400)
          end
        end

        desc 'Generate a CE/Registry CTID'
        get 'ctid' do
          { ctid: Envelope.generate_ctid }
        end
      end
    end
  end
end
