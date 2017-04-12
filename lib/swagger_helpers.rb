# TODO: Don't monkey patch
module Swagger
  module Blocks
    module Nodes
      # define common parameters to be used on the operation definitions
      class OperationNode
        def community_name
          {
            name: :community_name,
            in: :path,
            type: :string,
            required: true,
            description: 'Unique community name'
          }
        end

        def page_param
          {
            name: :page,
            in: :query,
            type: :integer,
            format: :int32,
            default: 1,
            required: false,
            description: 'Page number'
          }
        end

        def per_page_param
          {
            name: :per_page,
            in: :query,
            type: :integer,
            format: :int32,
            default: 10,
            required: false,
            description: 'Items per page'
          }
        end

        def envelope_id
          {
            name: :envelope_id,
            in: :body,
            type: :string,
            required: true,
            description: 'Unique envelope identifier'
          }
        end

        def request_envelope
          {
            name: :Envelope,
            in: :body,
            required: true,
            schema: { '$ref': '#/definitions/RequestEnvelope' }
          }
        end

        def delete_token
          {
            name: :DeleteToken,
            in: :body,
            required: true,
            schema: { '$ref': '#/definitions/DeleteToken' }
          }
        end

        def include_deleted
          {
            name: :include_deleted,
            in: :query,
            type: :string,
            required: false,
            description: 'Whether entries marked as deleted should be ' \
                         'included (Accepts: "true" or "only")'
          }
        end

        def parameters_for_search
          parameter page_param
          parameter per_page_param

          parameter name: :fts,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Full-text search term'
          parameter name: :community,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Filter by community'
          parameter name: :type,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Filter by type ("paradata" or ' \
                                 '"resource_data")'
          parameter name: :from,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Filter by date range'
          parameter name: :until,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Filter by date range'
          parameter name: :resource_type,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Filter by community-specific resource_type'
        end
      end
    end
  end
end
