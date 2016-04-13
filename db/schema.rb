# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160407152817) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "envelopes", force: :cascade do |t|
    t.integer  "envelope_type",       default: 0,  null: false
    t.string   "envelope_version",                 null: false
    t.string   "envelope_id",                      null: false
    t.text     "resource",                         null: false
    t.integer  "resource_format",     default: 0,  null: false
    t.integer  "resource_encoding",   default: 0,  null: false
    t.text     "resource_public_key",              null: false
    t.text     "node_headers"
    t.integer  "node_headers_format", default: 0
    t.jsonb    "processed_resource",  default: {}, null: false
    t.datetime "deleted_at"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "envelopes", ["envelope_id"], name: "index_envelopes_on_envelope_id", unique: true, using: :btree
  add_index "envelopes", ["envelope_version"], name: "index_envelopes_on_envelope_version", using: :btree
  add_index "envelopes", ["processed_resource"], name: "index_envelopes_on_processed_resource", using: :gin

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",               null: false
    t.integer  "item_id",                 null: false
    t.string   "event",                   null: false
    t.string   "whodunnit"
    t.jsonb    "object",     default: {}
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["object"], name: "index_versions_on_object", using: :gin

end
