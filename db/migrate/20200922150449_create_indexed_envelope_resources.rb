class CreateIndexedEnvelopeResources < ActiveRecord::Migration[5.2]
  def change
    create_table :indexed_envelope_resources do |t|
      t.string :'@id', null: false
      t.string :'@type', null: false
      t.string :'ceterms:ctid'
      t.datetime :'search:recordCreated', null: false
      t.string :'search:recordOwnedBy'
      t.string :'search:recordPublishedBy'
      t.datetime :'search:recordUpdated', null: false
      t.references :envelope_community,
                   foreign_key: { on_delete: :cascade },
                   index: false,
                   null: false
      t.references :envelope_resource,
                   foreign_key: { on_delete: :cascade },
                   index: { name: 'i_ctdl_envelope_resource_id' },
                   null: false
      t.datetime :created_at, null: false
      t.jsonb :payload, default: '{}', null: false
      t.boolean :public_record,
                default: true,
                index: { name: 'i_ctdl_public_record' },
                null: false

      t.foreign_key :organizations,
                    column: :'search:recordOwnedBy',
                    on_delete: :nullify,
                    primary_key: :_ctid
      t.foreign_key :organizations,
                    column: :'search:recordPublishedBy',
                    on_delete: :nullify,
                    primary_key: :_ctid

      t.index :'@id', name: 'i_ctdl_id', unique: true
      t.index :'@id',
              name: 'i_ctdl_id_trgm',
              opclass: { :'@id' => :gin_trgm_ops },
              using: :gin
      t.index :'@type', name: 'i_ctdl_type'
      t.index %i[envelope_community_id ceterms:ctid],
              name: 'i_ctdl_ceterms_ctid',
              unique: true
      t.index :'ceterms:ctid',
              name: 'i_ctdl_ceterms_ctid_trgm',
              opclass: { :'ceterms:ctid' => :gin_trgm_ops },
              using: :gin
      t.index :'search:recordCreated', name: 'i_ctdl_search_recordCreated_asc'
      t.index :'search:recordCreated',
              name: 'i_ctdl_search_recordCreated_desc',
              order: { 'search:recordCreated': :desc }
      t.index :'search:recordOwnedBy', name: 'i_ctdl_search_ownedBy'
      t.index :'search:recordPublishedBy', name: 'i_ctdl_search_publishedBy'
      t.index :'search:recordUpdated', name: 'i_ctdl_search_recordUpdated_asc'
      t.index :'search:recordUpdated',
              name: 'i_ctdl_search_recordUpdated_desc',
              order: { 'search:recordUpdated': :desc }
    end
  end
end
