class AddResourcePublishTypeToEnvelopes < ActiveRecord::Migration[6.0]
  def change
    add_column :envelopes, :resource_publish_type, :string
  end
end
