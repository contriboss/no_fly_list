# frozen_string_literal: true

class CreateTaggingTruck < ActiveRecord::Migration[7.2]
  def change
    create_table :truck_tags, id: :bigint do |t|
      t.string :name, null: false
      t.timestamp :created_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp :updated_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end

    create_table :truck_taggings do |t|
      t.column :taggable_id, :bigint, null: false, index: true # Change to :uuid if you are using UUIDs
      t.bigint :tag_id, null: false, index: true
      t.string :context, null: false
      t.timestamp :created_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp :updated_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end

    add_index :truck_tags, :name, unique: true
    add_index :truck_taggings, %i[taggable_id tag_id], unique: true
    add_foreign_key :truck_taggings, :truck_tags, column: :tag_id
    add_foreign_key :truck_taggings, :trucks, column: :taggable_id
  end
end
