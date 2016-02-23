module API
  # Implements all the endpoints related to documents
  class Documents < Grape::API
    resource :documents do
      get do
        'Listing documents...'
      end
    end
  end
end
