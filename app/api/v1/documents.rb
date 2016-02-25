require 'document'
require 'entities/document'

module API
  module V1
    # Implements all the endpoints related to documents
    class Documents < Grape::API
      include API::V1::Defaults

      resource :documents do
        desc 'Retrieve all documents ordered by date'
        get do
          documents = Document.ordered_by_date

          present documents, with: API::Entities::Document
        end
      end
    end
  end
end
