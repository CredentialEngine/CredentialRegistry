class CreateEnvelopeDumps < ActiveRecord::Migration
  def change
    create_table :envelope_dumps do |t|
      t.string :provider, null: false, default: 'archive.org'
      t.string :item, null: false
      t.string :location, null: false
      t.date :dumped_at, null: false, index: {unique: true}

      t.timestamps null: false
    end
  end
end
