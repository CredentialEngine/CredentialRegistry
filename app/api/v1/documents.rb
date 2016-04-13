require 'document'
require 'learning_registry_metadata'
require 'entities/document'
require 'helpers/shared_params'
require 'v1/versions'

module API
  module V1
    # Implements all the endpoints related to documents
    class Documents < Grape::API
      include API::V1::Defaults

      helpers SharedParams

      resource :documents do
        desc 'Retrieve all documents ordered by date'
        params do
          use :pagination
        end
        get do
          documents = Document.ordered_by_date
                              .page(params[:page])
                              .per(params[:per_page])

          present documents, with: API::Entities::Document
        end

        desc 'Publish a new document'
        params do
          use :document
        end
        post do
          document = Document.new(processed_params)

          if document.save
            body false
            status :created
          else
            error!({ errors: document.errors.full_messages },
                   :unprocessable_entity)
          end
        end

        route_param :document_id do
          before do
            @document = Document.find_by!(doc_id: params[:document_id])
          end

          desc 'Retrieves an envelope by identifier'
          get do
            present @document, with: API::Entities::Document
          end

          desc 'Updates an existing document'
          params do
            use :document
          end
          patch do
            if @document.update_attributes(processed_params)
              body false
              status :no_content
            else
              error!({ errors: @document.errors.full_messages },
                     :unprocessable_entity)
            end
          end

          desc 'Mark an existing document as deleted'
          delete do
            @document.update_attribute(:deleted_at, Time.current)

            body false
            status :no_content
          end

          mount API::V1::Versions
        end
      end
    end
  end
end
