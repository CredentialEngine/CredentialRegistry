require 'helpers/community_helpers'
require 'helpers/envelope_helpers'

module API
  module V1
    # Indexed resources API endpoints
    class IndexedResources < MountableAPI
      mounted do
        helpers CommunityHelpers
        helpers SharedHelpers

        before do
          authenticate!
        end

        resources :indexed_resources do
          desc 'Retrieves the indexed resources schema'
          get 'schema' do
            IndexedEnvelopeResource.columns_hash
          end

          desc 'Retrives an indexed resources by its CTID'
          params do
            requires :ctid, type: String, desc: 'CTID'
          end
          get ':ctid' do
            EnvelopeCommunity
              .find_by!(name: select_community)
              .indexed_envelope_resources
              .find_by!('ceterms:ctid' => params[:ctid])
          rescue ActiveRecord::RecordNotFound
            raise ActiveRecord::RecordNotFound.new("Couldn't find the indexed resource")
          end
        end
      end
    end
  end
end
