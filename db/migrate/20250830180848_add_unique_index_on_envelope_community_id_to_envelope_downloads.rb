class AddUniqueIndexOnEnvelopeCommunityIdToEnvelopeDownloads < ActiveRecord::Migration[8.0]
  def change
    ActiveRecord::Base.transaction do
      reversible do |dir|
        dir.up do
          ActiveRecord::Base.connection.execute(<<~COMMAND)
            DELETE FROM envelope_downloads
            WHERE created_at NOT IN (
                SELECT max_created_at
                FROM (
                    SELECT MAX(created_at ) as max_created_at
                    FROM envelope_downloads
                    GROUP BY envelope_community_id
                ) AS t
            );
          COMMAND
        end
      end

      remove_index :envelope_downloads, :envelope_community_id
      add_index :envelope_downloads, :envelope_community_id, unique: true
    end
  end
end
