class RemovePublicKeyAndResourceFromEnvelopes < ActiveRecord::Migration[8.0]
  def change
    remove_column :envelopes, :resource, :text
    remove_column :envelopes, :resource_public_key, :string
  end
end
