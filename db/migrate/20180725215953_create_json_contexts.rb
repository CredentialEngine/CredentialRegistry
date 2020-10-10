class CreateJsonContexts < ActiveRecord::Migration[4.2]
  def change
    create_table :json_contexts do |t|
      t.string :url, null: false
      t.jsonb :context, null: false
      t.timestamps null: false
    end

    add_index :json_contexts, :url, unique: true
    add_index :json_contexts, :context, using: :gin
  end
end
