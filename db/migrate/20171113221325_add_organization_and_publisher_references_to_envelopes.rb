class AddOrganizationAndPublisherReferencesToEnvelopes < ActiveRecord::Migration
  def change
    change_table :envelopes do |t|
      t.references :organization, foreign_key: true, type: :uuid
      t.references :publisher, foreign_key: true, type: :uuid
    end
  end
end
