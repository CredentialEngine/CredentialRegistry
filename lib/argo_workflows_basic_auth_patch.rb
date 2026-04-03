require 'argo_workflows_api_client/configuration'

module ArgoWorkflowsApiClient
  module BasicAuthPatch
    def auth_settings
      auth_value =
        if username.present? && password.present?
          basic_auth_token
        else
          api_key_with_prefix('Authorization')
        end

      {
        'BearerToken' => {
          type: 'api_key',
          in: 'header',
          key: 'Authorization',
          value: auth_value
        }
      }
    end
  end
end

ArgoWorkflowsApiClient::Configuration.prepend(ArgoWorkflowsApiClient::BasicAuthPatch)
