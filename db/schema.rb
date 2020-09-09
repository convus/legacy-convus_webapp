# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_09_09_025230) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assertion_citations", force: :cascade do |t|
    t.bigint "assertion_id"
    t.bigint "citation_id"
    t.boolean "direct_quotation", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["assertion_id"], name: "index_assertion_citations_on_assertion_id"
    t.index ["citation_id"], name: "index_assertion_citations_on_citation_id"
  end

  create_table "assertions", force: :cascade do |t|
    t.text "body"
    t.text "slug"
    t.json "previous_slugs"
    t.bigint "creator_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["creator_id"], name: "index_assertions_on_creator_id"
  end

  create_table "citations", force: :cascade do |t|
    t.bigint "publisher_id"
    t.text "title"
    t.text "slug"
    t.text "authors"
    t.integer "kind"
    t.text "url"
    t.datetime "published_at"
    t.bigint "creator_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["creator_id"], name: "index_citations_on_creator_id"
    t.index ["publisher_id"], name: "index_citations_on_publisher_id"
  end

  create_table "publications", force: :cascade do |t|
    t.text "title"
    t.text "slug"
    t.boolean "has_issued_retractions", default: false
    t.text "home_url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.json "github_auth"
    t.json "json"
    t.string "github_id"
    t.string "username"
    t.integer "role"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
