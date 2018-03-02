class AddCtidToOrganizations < ActiveRecord::Migration
  def change
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute('LOCK organizations IN SHARE ROW EXCLUSIVE MODE')

      add_column :organizations, :_ctid, :string
      add_index :organizations, :_ctid, unique: true

      Organization.where('_ctid is null').each do |o|
        o.update_column(:_ctid, "ce-#{SecureRandom.uuid}")
      end

      change_column_null :organizations, :_ctid, false
    end

    # remove uniqueness constraint from name field since we're now using _ctid
    # as the main identifier

    remove_index :organizations, :name
    add_index :organizations, :name
  end
end
