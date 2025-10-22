class AddS3UrlToEnvelopes < ActiveRecord::Migration[8.0]
  def change
    add_column :envelopes, :s3_url, :string
    add_index :envelopes, :s3_url, unique: true
  end
end
