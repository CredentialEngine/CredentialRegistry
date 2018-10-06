require 'helpers/shared_helpers'
require 'swagger_docs'

module API
  module V1
    # Root api endpoints
    class Root < Grape::API
      helpers SharedHelpers
      helpers do
        # Metadata communities hash with 'name => url' pairs.
        # Return: [Hash]
        #   { community1: 'url/for/comm1', ..., communityN : 'url/for/commN' }
        def metadata_communities
          communities = EnvelopeCommunity.pluck(:name).flat_map do |name|
            [name, url(name.dasherize)]
          end
          Hash[*communities]
        end
      end

      desc 'API root'
      get do
        {
          api_version: MetadataRegistry::VERSION,
          total_envelopes: Envelope.not_deleted.count,
          metadata_communities: metadata_communities,
          info: url(:info)
        }
      end

      desc 'Gives general info about the api node'
      get :info do
        {
          metadata_communities: metadata_communities,
          postman: 'https://www.getpostman.com/collections/bc38edc491333b643e23',
          swagger: url(:swagger, 'index.html'),
          readme: 'https://github.com/CredentialEngine/CredentialRegistry/blob/master/README.md',
          docs: 'https://github.com/CredentialEngine/CredentialRegistry/tree/master/docs'
        }
      end

      desc 'Render `swagger.json`'
      get ':swagger_json', requirements: { swagger_json: 'swagger.json' } do
        swagger_json = Swagger::Blocks.build_root_json [MR::SwaggerDocs]
        present swagger_json.merge(host: request.host_with_port)
      end
    end
  end
end
