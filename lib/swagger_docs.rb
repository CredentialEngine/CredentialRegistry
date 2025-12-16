require 'ctdl_query'
require 'swagger_docs/models'
require 'swagger_docs/sections/admin'
require 'swagger_docs/sections/containers'
require 'swagger_docs/sections/description_sets'
require 'swagger_docs/sections/envelopes'
require 'swagger_docs/sections/general'
require 'swagger_docs/sections/graphs'
require 'swagger_docs/sections/indexer'
require 'swagger_docs/sections/resources'
require 'swagger_docs/sections/search'
require 'swagger_helpers'

module MetadataRegistry
  # Swagger docs definition
  class SwaggerDocs
    include Swagger::Blocks

    include Models
    include Sections::General
    include Sections::Admin
    include Sections::Containers
    include Sections::DescriptionSets
    include Sections::Envelopes
    include Sections::Graphs
    include Sections::Indexer
    include Sections::Resources
    include Sections::Search

    swagger_root do
      key :swagger, '2.0'
      info do
        key :title, 'CE/Registry API'
        key :description, 'Documentation for the new API endpoints. ' \
                          'You can check more detailed info on: ' \
                          'https://github.com/CredentialEngine/CredentialRegistry/blob/master/README.md#docs'
        key :version, 'v1'

        contact name: 'CE/Registry',
                email: 'learningreg-dev@googlegroups.com',
                url: 'https://github.com/CredentialEngine/CredentialRegistry'

        license name: 'Apache License, Version 2.0',
                url: 'http://www.apache.org/licenses/LICENSE-2.0'
      end
      key :consumes, ['application/json']
      key :produces, ['application/json']

      security_definition :bearerAuth do
        key :type, :apiKey
        key :name, 'Authorization'
        key :in, :header
        key :description, 'Bearer token authentication'
      end

      security do
        key :bearerAuth, []
      end
    end
  end
end
