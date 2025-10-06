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

ActiveRecord::Schema[8.0].define(version: 27) do
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

  create_table "bus_taggings", force: :cascade do |t|
    t.bigint "taggable_id", null: false
    t.bigint "tag_id", null: false
    t.string "context", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["tag_id"], name: "index_bus_taggings_on_tag_id"
    t.index ["taggable_id", "tag_id"], name: "index_bus_taggings_on_taggable_id_and_tag_id", unique: true
    t.index ["taggable_id"], name: "index_bus_taggings_on_taggable_id"
  end

  create_table "bus_tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["name"], name: "index_bus_tags_on_name", unique: true
  end

  create_table "buses", force: :cascade do |t|
    t.string "route_number"
    t.integer "capacity"
    t.string "company"
    t.boolean "accessible"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "car_taggings", force: :cascade do |t|
    t.bigint "taggable_id", null: false
    t.bigint "tag_id", null: false
    t.string "context", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["tag_id"], name: "index_car_taggings_on_tag_id"
    t.index ["taggable_id", "tag_id"], name: "index_car_taggings_on_taggable_id_and_tag_id", unique: true
    t.index ["taggable_id"], name: "index_car_taggings_on_taggable_id"
  end

  create_table "car_tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["name"], name: "index_car_tags_on_name", unique: true
  end

  create_table "cars", force: :cascade do |t|
    t.string "make"
    t.string "model"
    t.integer "year"
    t.string "color"
    t.integer "price_cents"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "truck_taggings", force: :cascade do |t|
    t.bigint "taggable_id", null: false
    t.bigint "tag_id", null: false
    t.string "context", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["tag_id"], name: "index_truck_taggings_on_tag_id"
    t.index ["taggable_id", "tag_id"], name: "index_truck_taggings_on_taggable_id_and_tag_id", unique: true
    t.index ["taggable_id"], name: "index_truck_taggings_on_taggable_id"
  end

  create_table "truck_tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["name"], name: "index_truck_tags_on_name", unique: true
  end

  create_table "trucks", force: :cascade do |t|
    t.string "make"
    t.string "model"
    t.integer "year"
    t.integer "capacity_tons"
    t.string "driver_name"
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  add_foreign_key "application_taggings", "application_tags", column: "tag_id"
  add_foreign_key "bus_taggings", "bus_tags", column: "tag_id"
  add_foreign_key "bus_taggings", "buses", column: "taggable_id"
  add_foreign_key "car_taggings", "car_tags", column: "tag_id"
  add_foreign_key "car_taggings", "cars", column: "taggable_id"
  add_foreign_key "truck_taggings", "truck_tags", column: "tag_id"
  add_foreign_key "truck_taggings", "trucks", column: "taggable_id"
end
