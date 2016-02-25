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

ActiveRecord::Schema.define(version: 20160223171632) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "documents", force: :cascade do |t|
    t.integer  "doc_type",             default: 0, null: false
    t.string   "doc_version",                      null: false
    t.string   "doc_id",                           null: false
    t.text     "user_envelope",                    null: false
    t.integer  "user_envelope_format", default: 0, null: false
    t.text     "node_headers"
    t.integer  "node_headers_format",  default: 0
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
  end

  add_index "documents", ["doc_id"], name: "index_documents_on_doc_id", unique: true, using: :btree
  add_index "documents", ["doc_version"], name: "index_documents_on_doc_version", using: :btree

end
