class AddSearchRecordPublishTypeToIndexedEnvelopeResources < ActiveRecord::Migration[6.0]
  def change
    add_column :indexed_envelope_resources, :"search:resourcePublishType", :string
    add_index :indexed_envelope_resources, :"search:resourcePublishType", name: "i_ctdl_search_resourcePublishType"
  end
end
