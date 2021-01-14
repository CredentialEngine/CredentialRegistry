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

        def resource_id
          {
            name: :resource_id,
            in: :path,
            type: :string,
            required: true,
            description: 'Unique resource identifier'
          }
        end

        def envelope_id
          {
            name: :envelope_id,
            in: :path,
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
          parameter name: :envelope_ceterms_ctid,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Filter by envelope CTID'
          parameter name: :envelope_id,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Filter by envelope ID'
          parameter name: :envelope_ctdl_type,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Filter by envelope CTDL type'
          parameter name: :owned_by,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Filter by owner CTID'
          parameter name: :published_by,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Filter by publisher CTID'
          parameter name: :sort_by,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Sort by timestamp ' \
                                 '(`created_at` or `updated_at`)'
          parameter name: :sort_order,
                    in: :query,
                    type: :string,
                    required: false,
                    description: 'Sort order (`asc` or `desc`)'
        end

        def auth_token
          {
            name: :auth_token,
            in: :header,
            type: :string,
            required: true,
            description: 'The auth token of the user performing the action, '\
                          'in the Authorization header like \'Authorization: Token {token}\''
          }
        end

        def organization_id(description:, name: nil, required: true)
          {
            name: name || :organization_id,
            in: :path,
            type: :string,
            required: required,
            description: description
          }
        end

        def resource
          {
            name: :resource,
            in: :body,
            type: :json,
            required: true,
            description: 'The resource being published'
          }
        end

        def ctid(description: nil)
          {
            name: :ctid,
            in: :path,
            type: :string,
            required: true,
            description: description || 'The CTID of a document'
          }
        end

        def ctids(description: nil)
          {
            name: :ctids,
            in: :body,
            type: :array,
            required: true,
            description: description || 'Array of CTIDs'
          }
        end

        def new_organization_id
          {
            name: :organization_id,
            in: :query,
            type: :string,
            required: true,
            description: 'The ID of the organization to which a document in transferred'
          }
        end

        def purge
          {
            name: :purge,
            in: :query,
            type: :boolean,
            required: false,
            description: 'Whether the document should be physically deleted'
          }
        end

        def published_by
          {
            name: :published_by,
            in: :query,
            type: :string,
            required: false,
            description: 'The CTID of the publishing organization'
          }
        end
      end
    end
  end
end
