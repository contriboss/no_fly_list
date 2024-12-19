# frozen_string_literal: true

class CreateTaggingBus < ActiveRecord::Migration[7.2]
  def change
    create_table :bus_tags, id: :bigint do |t|
      t.string :name, null: false
      t.timestamp :created_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp :updated_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end

    create_table :bus_taggings do |t|
      t.column :taggable_id, :bigint, null: false, index: true # Change to :uuid if you are using UUIDs
      t.column :tag_id, :bigint, null: false, index: true
      t.string :context, null: false
      t.timestamp :created_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp :updated_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end

    add_index :bus_tags, :name, unique: true
    add_index :bus_taggings, %i[taggable_id tag_id], unique: true
    add_foreign_key :bus_taggings, :bus_tags, column: :tag_id
    add_foreign_key :bus_taggings, :buses, column: :taggable_id
  end
end
