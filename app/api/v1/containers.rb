require 'container_repository'

module API
  module V1
    # Implements the endpoints related to containers
    class Containers < MountableAPI
      mounted do
        namespace 'containers/:container_ctid/resources' do
          post do
          end

          delete ':resource_ctid' do
          end
        end
      end
    end
  end
end
