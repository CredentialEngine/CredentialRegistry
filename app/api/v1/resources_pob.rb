module API
  module V1
    # Default options for all API endpoints and versions
    module ResourcesPob
      extend ActiveSupport::Concern

      included do
        desc 'Takes a resource and an organization id, signs the resource '\
             'on behalf of an organization, and publishes a new envelope with '\
             'that signed resource',
             http_codes: [
               { code: 201, message: 'Envelope created' },
               { code: 200, message: 'Envelope updated' }
             ]
        params do
          use :update_if_exists
          use :skip_validation
        end
        post 'organizations/:organization_id/documents' do
          authenticate!
          params[:envelope_community] = select_community

          puts params[:envelope_community]
          puts params[:organization_id]
        end
      end
    end
  end
end
