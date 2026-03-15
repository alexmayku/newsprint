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

ActiveRecord::Schema[8.1].define(version: 2026_03_15_195552) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.string "author"
    t.text "body_html", null: false
    t.datetime "created_at", null: false
    t.text "image_urls", default: [], array: true
    t.text "link_urls", default: [], array: true
    t.bigint "newsletter_id", null: false
    t.integer "position", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["newsletter_id"], name: "index_articles_on_newsletter_id"
  end

  create_table "newsletters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "est_pages", null: false
    t.datetime "latest_issue_date", null: false
    t.string "logo_url"
    t.string "sender_email", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "sender_email"], name: "index_newsletters_on_user_id_and_sender_email", unique: true
    t.index ["user_id"], name: "index_newsletters_on_user_id"
  end

  create_table "newspapers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "delivery_address", default: {}, null: false
    t.integer "frequency"
    t.bigint "newsletter_ids", default: [], null: false, array: true
    t.bigint "newspaper_id"
    t.integer "order_type", default: 0, null: false
    t.integer "page_count", null: false
    t.string "pdf_url"
    t.integer "status", default: 0, null: false
    t.string "stripe_payment_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["newspaper_id"], name: "index_orders_on_newspaper_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "qr_references", force: :cascade do |t|
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.string "label", null: false
    t.text "qr_svg"
    t.integer "reference_number", null: false
    t.datetime "updated_at", null: false
    t.text "url", null: false
    t.index ["article_id"], name: "index_qr_references_on_article_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "delivery_address"
    t.string "email", null: false
    t.text "google_token_enc"
    t.string "stripe_customer_id"
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_LOWER_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "articles", "newsletters"
  add_foreign_key "newsletters", "users"
  add_foreign_key "orders", "newspapers"
  add_foreign_key "orders", "users"
  add_foreign_key "qr_references", "articles"
end
