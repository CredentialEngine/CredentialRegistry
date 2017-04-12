require 'helpers/shared_helpers'

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
          total_envelopes: Envelope.count,
          metadata_communities: metadata_communities,
          info: url(:info)
        }
      end

      desc 'Gives general info about the api node'
      get :info do
        {
          metadata_communities: metadata_communities,
          postman: 'https://www.getpostman.com/collections/bc38edc491333b643e23',
          swagger: url(:swagger_doc),
          readme: 'https://github.com/learningtapestry/metadataregistry/blob/master/README.md',
          docs: 'https://github.com/learningtapestry/metadataregistry/tree/master/docs'
        }
      end
    end
  end
end
