module API
  module V1
    # Implements all the endpoints related to resources
    class Resources < Grape::API
      include API::V1::Defaults

      helpers SharedHelpers

      resource :resources do
        desc 'Return a resource.'
        params do
          requires :id, type: String, desc: 'Resource id.'
        end
        route_param :id do
          get do
            envelope = Envelope.where('processed_resource @> ?',
                                      { 'ceterms:ctid' => params[:id] }.to_json)
                               .first

            if envelope.blank?
              err = ['No matching resource found']
              json_error! err, nil, :not_found
            end

            present envelope.processed_resource
          end
        end
      end
    end
  end
end
