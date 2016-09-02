module MetadataRegistry
  # Swagger docs definition
  class SwaggerDocs
    include Swagger::Blocks

    swagger_root do
      key :swagger, '2.0'
      info do
        key :version, 'v1'
        key :title, 'MetadataRegistry API'
        key :description, 'Documentation for the new API endpoints'
        contact do
          key :name, 'Metadata Registry'
          key :email, 'learningreg-dev@googlegroups.com'
          key :url, 'https://github.com/learningtapestry/metadataregistry'
        end
        license do
          key :name, 'Apache License, Version 2.0'
          key :url, 'http://www.apache.org/licenses/LICENSE-2.0'
        end
      end
      key :host, 'lr-staging.learningtapestry.com'
      key :consumes, [
        'application/json'
      ]
      key :produces, [
        'application/xml',
        'application/json',
        'application/octet-stream',
        'text/plain'
      ]
    end

    swagger_path '/' do
      operation :get do
        response 200
      end
    end
  end
end
