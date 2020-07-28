class CreateDescriptionSets < ActiveRecord::Migration
  def change
    create_table :description_sets do |t|
      t.string :ceterms_ctid, null: false
      t.string :path, null: false
      t.string :uris, array: true, default: [], null: false

      t.index %i[ceterms_ctid path], unique: true
    end
  end
end
