# frozen_string_literal: true

class CreateVehicles < ActiveRecord::Migration[7.2]
  def change
    create_table :vehicles do |t|
      t.string :type, null: false
      t.string :name
      t.integer :year

      t.timestamp :created_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp :updated_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end

    create_table :vehicle_tags do |t|
      t.string :name, null: false
      t.index :name, unique: true
    end

    create_table :vehicle_taggings do |t|
      t.bigint :tag_id, null: false
      t.foreign_key :vehicle_tags, column: :tag_id
      t.bigint :taggable_id, null: false
      t.foreign_key :vehicles, column: :taggable_id
      t.string :context, null: false

      t.index %i[taggable_id tag_id], name: "index_vehicle_taggings_on_taggable_id_and_tag_id", unique: true
      t.index :tag_id, name: "index_vehicle_taggings_on_tag_id"
      t.index :taggable_id, name: "index_vehicle_taggings_on_taggable_id"
    end
  end
end
