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

ActiveRecord::Schema[7.0].define(version: 2022_09_22_012134) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_enum :invitation_status, [
    "pending",
    "accepted",
    "rejected",
    "expired",
    "ignored",
    "revoked",
    "sent",
  ], force: :cascade

  create_enum :membership_status, [
    "active",
    "revoked",
  ], force: :cascade

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "authentication_methods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "person_id"
    t.string "contact_method", null: false
    t.string "contact_location", null: false
    t.datetime "confirmed_at", precision: nil
    t.text "one_time_password_secret_ciphertext"
    t.string "encrypted_one_time_password_secret_iv"
    t.datetime "last_one_time_password_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_method", "contact_location"], name: "index_authentication_methods_on_contact_fields", unique: true
    t.index ["person_id"], name: "index_authentication_methods_on_person_id"
  end

  create_table "clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at", precision: nil
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_type", "sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_type_and_sluggable_id"
  end

  create_table "furniture_placements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "slot"
    t.string "furniture_kind"
    t.jsonb "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "room_id"
    t.index ["room_id"], name: "index_furniture_placements_on_room_id"
  end

  create_table "invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "space_id"
    t.string "name", null: false
    t.string "email", null: false
    t.datetime "last_sent_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "invitor_id"
    t.enum "status", default: "pending", null: false, enum_type: "invitation_status"
    t.index ["invitor_id"], name: "index_invitations_on_invitor_id"
    t.index ["space_id"], name: "index_invitations_on_space_id"
  end

  create_table "items", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "location_id"
    t.jsonb "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "space_id"
    t.index ["location_id"], name: "index_items_on_location_id"
    t.index ["space_id"], name: "index_items_on_space_id"
  end

  create_table "marketplace_products", force: :cascade do |t|
    t.uuid "space_id"
    t.string "name"
    t.string "description"
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["space_id"], name: "index_marketplace_products_on_space_id"
  end

  create_table "memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "member_id"
    t.uuid "space_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "invitation_id"
    t.enum "status", default: "active", null: false, enum_type: "membership_status"
    t.index ["invitation_id"], name: "index_memberships_on_invitation_id"
    t.index ["member_id"], name: "index_memberships_on_member_id"
    t.index ["space_id"], name: "index_memberships_on_space_id"
  end

  create_table "people", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_people_on_email", unique: true
  end

  create_table "rooms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "access_level", default: "unlocked", null: false
    t.string "access_code"
    t.string "publicity_level"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "space_id"
    t.index ["slug", "space_id"], name: "index_rooms_on_slug_and_space_id", unique: true
    t.index ["space_id"], name: "index_rooms_on_space_id"
  end

  create_table "spaces", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id"
    t.string "jitsi_meet_domain"
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "branded_domain"
    t.uuid "entrance_id"
    t.string "theme"
    t.index ["client_id"], name: "index_spaces_on_client_id"
    t.index ["slug", "client_id"], name: "index_spaces_on_slug_and_client_id", unique: true
  end

  create_table "utility_hookups", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "space_id"
    t.string "name", null: false
    t.string "utility_slug", null: false
    t.string "status", default: "unavailable", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "configuration_ciphertext"
    t.index ["space_id"], name: "index_utility_hookups_on_space_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "marketplace_products", "spaces"
  add_foreign_key "memberships", "invitations"
  add_foreign_key "spaces", "rooms", column: "entrance_id"
end
