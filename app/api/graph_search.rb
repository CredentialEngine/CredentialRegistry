require 'graphql'
require_relative 'graph_search/types'

module API
  # GraphQL Search Interface for CE
  class GraphSearch < Grape::API
    format :json

    desc 'GraphQL Search Interface for Credential Engine'
    params do
      requires :query, type: String, desc: 'The GraphQL search query'
      optional :variables, type: Hash, desc: 'Conditions and extra options related to the query'
    end
    post '/graph-search' do
      status :ok
      Schema.execute(params[:query], variables: params[:variables])
    end
  end
end
