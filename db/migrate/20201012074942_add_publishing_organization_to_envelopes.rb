class AddPublishingOrganizationToEnvelopes < ActiveRecord::Migration[5.2]
  def change
    add_reference :envelopes,
                  :publishing_organization,
                  foreign_key: { to_table: :organizations },
                  type: :uuid
  end
end
