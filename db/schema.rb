# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_09_12_183059) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "citations", force: :cascade do |t|
    t.bigint "publication_id"
    t.text "title"
    t.text "slug"
    t.datetime "published_at"
    t.integer "kind"
    t.text "url"
    t.boolean "url_is_direct_link_to_full_text", default: false
    t.text "wayback_machine_url"
    t.bigint "creator_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.text "path_slug"
    t.datetime "approved_at"
    t.integer "pull_request_number"
    t.boolean "url_is_not_publisher", default: false
    t.boolean "randomized_controlled_trial", default: false
    t.boolean "peer_reviewed", default: false
    t.boolean "submitting_to_github", default: false
    t.text "doi"
    t.jsonb "authors"
    t.integer "removed_pull_request_number"
    t.index ["creator_id"], name: "index_citations_on_creator_id"
    t.index ["publication_id"], name: "index_citations_on_publication_id"
  end

  create_table "content_commits", force: :cascade do |t|
    t.string "sha"
    t.json "github_data"
    t.string "author"
    t.datetime "committed_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "explanation_quotes", force: :cascade do |t|
    t.bigint "explanation_id"
    t.bigint "citation_id"
    t.bigint "creator_id"
    t.integer "ref_number"
    t.text "text"
    t.text "url"
    t.boolean "removed", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "hypothesis_id"
    t.index ["citation_id"], name: "index_explanation_quotes_on_citation_id"
    t.index ["creator_id"], name: "index_explanation_quotes_on_creator_id"
    t.index ["explanation_id"], name: "index_explanation_quotes_on_explanation_id"
    t.index ["hypothesis_id"], name: "index_explanation_quotes_on_hypothesis_id"
  end

  create_table "explanations", force: :cascade do |t|
    t.bigint "hypothesis_id"
    t.bigint "creator_id"
    t.text "text"
    t.text "body_html"
    t.integer "ref_number"
    t.integer "listing_order"
    t.datetime "approved_at"
    t.integer "pull_request_number"
    t.boolean "submitting_to_github", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "removed_pull_request_number"
    t.index ["creator_id"], name: "index_explanations_on_creator_id"
    t.index ["hypothesis_id"], name: "index_explanations_on_hypothesis_id"
  end

  create_table "hypotheses", force: :cascade do |t|
    t.text "title"
    t.text "slug"
    t.bigint "creator_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "approved_at"
    t.integer "pull_request_number"
    t.boolean "submitting_to_github", default: false
    t.bigint "ref_number"
    t.string "ref_id"
    t.integer "removed_pull_request_number"
    t.index ["creator_id"], name: "index_hypotheses_on_creator_id"
    t.index ["ref_id"], name: "index_hypotheses_on_ref_id", unique: true
  end

  create_table "hypothesis_relations", force: :cascade do |t|
    t.bigint "creator_id"
    t.bigint "hypothesis_earlier_id"
    t.bigint "hypothesis_later_id"
    t.bigint "citation_id"
    t.bigint "explanation_quote_id"
    t.integer "kind"
    t.datetime "approved_at"
    t.integer "pull_request_number"
    t.integer "removed_pull_request_number"
    t.boolean "submitting_to_github", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["citation_id"], name: "index_hypothesis_relations_on_citation_id"
    t.index ["creator_id"], name: "index_hypothesis_relations_on_creator_id"
    t.index ["explanation_quote_id"], name: "index_hypothesis_relations_on_explanation_quote_id"
    t.index ["hypothesis_earlier_id"], name: "index_hypothesis_relations_on_hypothesis_earlier_id"
    t.index ["hypothesis_later_id"], name: "index_hypothesis_relations_on_hypothesis_later_id"
  end

  create_table "hypothesis_tags", force: :cascade do |t|
    t.bigint "hypothesis_id"
    t.bigint "tag_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["hypothesis_id"], name: "index_hypothesis_tags_on_hypothesis_id"
    t.index ["tag_id"], name: "index_hypothesis_tags_on_tag_id"
  end

  create_table "previous_titles", force: :cascade do |t|
    t.bigint "hypothesis_id"
    t.text "title"
    t.text "slug"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["hypothesis_id"], name: "index_previous_titles_on_hypothesis_id"
  end

  create_table "publications", force: :cascade do |t|
    t.text "title"
    t.text "slug"
    t.boolean "has_published_retractions", default: false
    t.boolean "has_peer_reviewed_articles", default: false
    t.text "home_url"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.jsonb "base_domains"
    t.boolean "meta_publication", default: false
    t.float "impact_factor"
  end

  create_table "tags", force: :cascade do |t|
    t.text "title"
    t.text "slug"
    t.integer "taxonomy"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "approved_at"
  end

  create_table "user_scores", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "hypothesis_id"
    t.integer "score"
    t.integer "kind"
    t.boolean "expired", default: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "explanation_id"
    t.index ["explanation_id"], name: "index_user_scores_on_explanation_id"
    t.index ["hypothesis_id"], name: "index_user_scores_on_hypothesis_id"
    t.index ["user_id"], name: "index_user_scores_on_user_id"
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
