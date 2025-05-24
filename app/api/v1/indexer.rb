require 'indexer_stats'
require 'helpers/community_helpers'
require 'helpers/envelope_helpers'

module API
  module V1
    # Indexed resources API endpoints
    class Indexer < MountableAPI
      mounted do
        include API::V1::Defaults

        helpers CommunityHelpers
        helpers SharedHelpers

        before do
          authenticate!
        end

        namespace :indexer do
          desc 'Shows how many indexing jobs are in the queue'
          get 'stats' do
            IndexerStats.call(select_community)
          end
        end
      end
    end
  end
end
