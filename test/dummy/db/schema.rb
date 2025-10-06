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

ActiveRecord::Schema[8.0].define(version: 17) do
  create_table "application_taggings", force: :cascade do |t|
    t.integer "tag_id", null: false
    t.string "taggable_type", null: false
    t.integer "taggable_id", null: false
    t.string "context", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["context"], name: "index_application_taggings_on_context"
    t.index ["tag_id"], name: "index_application_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id", "context", "tag_id"], name: "index_app_taggings_uniqueness", unique: true
    t.index ["taggable_type", "taggable_id"], name: "index_application_taggings_on_taggable"
  end

  create_table "application_tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["name"], name: "index_application_tags_on_name", unique: true
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.string "industry"
    t.integer "founded_year"
    t.string "ceo_name"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "company_taggings", force: :cascade do |t|
    t.bigint "taggable_id", null: false
    t.bigint "tag_id", null: false
    t.string "context", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["tag_id"], name: "index_company_taggings_on_tag_id"
    t.index ["taggable_id", "tag_id"], name: "index_company_taggings_on_taggable_id_and_tag_id", unique: true
    t.index ["taggable_id"], name: "index_company_taggings_on_taggable_id"
  end

  create_table "company_tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["name"], name: "index_company_tags_on_name", unique: true
  end

  create_table "military_carrier_taggings", force: :cascade do |t|
    t.bigint "taggable_id", null: false
    t.bigint "tag_id", null: false
    t.string "context", null: false
    t.index ["tag_id"], name: "index_military_carrier_taggings_on_tag_id"
    t.index ["taggable_id"], name: "index_military_carrier_taggings_on_taggable_id"
  end

  create_table "military_carrier_tags", force: :cascade do |t|
    t.string "name"
  end

  create_table "military_carriers", force: :cascade do |t|
    t.string "name"
    t.string "model"
    t.integer "capacity"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "passenger_taggings", force: :cascade do |t|
    t.bigint "taggable_id", null: false
    t.bigint "tag_id", null: false
    t.string "context", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["tag_id"], name: "index_passenger_taggings_on_tag_id"
    t.index ["taggable_id", "tag_id"], name: "index_passenger_taggings_on_taggable_id_and_tag_id", unique: true
    t.index ["taggable_id"], name: "index_passenger_taggings_on_taggable_id"
  end

  create_table "passenger_tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["name"], name: "index_passenger_tags_on_name", unique: true
  end

  create_table "passengers", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "passport_number"
    t.string "nationality"
    t.string "religion", default: "scientology"
    t.string "gender", default: "not_sure"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "special_needs_count", default: 0, null: false
    t.integer "dietary_requirements_count", default: 0, null: false
  end

  create_table "people", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.date "birthdate"
    t.string "email"
    t.text "address"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "person_taggings", force: :cascade do |t|
    t.bigint "tag_id", null: false
    t.bigint "taggable_id", null: false
    t.string "context", null: false
  end

  create_table "person_tags", force: :cascade do |t|
    t.string "name", null: false
  end

  add_foreign_key "application_taggings", "application_tags", column: "tag_id"
  add_foreign_key "company_taggings", "companies", column: "taggable_id"
  add_foreign_key "company_taggings", "company_tags", column: "tag_id"
  add_foreign_key "military_carrier_taggings", "military_carrier_tags", column: "tag_id"
  add_foreign_key "military_carrier_taggings", "military_carriers", column: "taggable_id"
  add_foreign_key "passenger_taggings", "passenger_tags", column: "tag_id"
  add_foreign_key "passenger_taggings", "passengers", column: "taggable_id"
  add_foreign_key "person_taggings", "people", column: "taggable_id"
  add_foreign_key "person_taggings", "person_tags", column: "tag_id"
end
