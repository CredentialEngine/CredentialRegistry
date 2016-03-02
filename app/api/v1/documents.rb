require 'document'
require 'entities/document'
require 'helpers/shared_params'

module API
  module V1
    # Implements all the endpoints related to documents
    class Documents < Grape::API
      include API::V1::Defaults

      helpers SharedParams

      resource :documents do
        desc 'Retrieve all documents ordered by date'
        get do
          documents = Document.ordered_by_date

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

        route_param :id do
          desc 'Updates an existing document'
          params do
            use :document
          end
          patch do
            document = Document.find_by!(doc_id: params[:id])

            if document.update_attributes(processed_params)
              body false
              status :no_content
            else
              error!({ errors: document.errors.full_messages },
                     :unprocessable_entity)
            end
          end

          desc 'Mark an existing document as deleted'
          delete do
            document = Document.find_by!(doc_id: params[:id])
            document.update_attribute(:deleted_at, Time.current)

            body false
            status :ok
          end
        end
      end
    end
  end
end
