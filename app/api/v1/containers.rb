require 'mountable_api'
require 'container_repository'
require 'helpers/shared_helpers'
require 'helpers/community_helpers'
require 'entities/envelope'

module API
  module V1
    # Implements the endpoints related to containers
    class Containers < MountableAPI
      mounted do # rubocop:todo Metrics/BlockLength
        helpers CommunityHelpers
        helpers SharedHelpers

        resource :containers do
          before do
            authenticate!
          end

          route_param :container_ctid do
            resource :resources do
              before do
                ctid = params[:container_ctid]&.downcase

                @envelope = current_community
                            .envelopes
                            .containers
                            .find_sole_by(envelope_ceterms_ctid: ctid)

                authorize @envelope, :update?
                @repository = ContainerRepository.new(@envelope)
              end

              desc "Appends URIs to the container's ceterms:hasMember"
              patch do
                @repository.add_member_uri(JSON.parse(request.body.read))
                present @envelope, with: API::Entities::Envelope
              end

              desc "Removes URIs from the container's ceterms:hasMember"
              delete do
                @repository.remove_member_uris(JSON.parse(request.body.read))
                present @envelope, with: API::Entities::Envelope
              end

            end
          end
        end
      end
    end
  end
end
