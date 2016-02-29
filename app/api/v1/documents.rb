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
          document = Document.new(declared(params).to_hash)

          if document.save
            body false
            status :created
          else
            error!({ errors: document.errors.full_messages },
                   :unprocessable_entity)
          end
        end

        desc 'Mark an existing document as deleted'
        params do
          requires :doc_id, type: String
        end
        delete ':doc_id' do
          document = Document.find_by!(doc_id: params[:doc_id])
          document.update_attribute(:deleted_at, Time.current)

          body false
          status :ok
        end
      end
    end
  end
end
