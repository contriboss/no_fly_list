# frozen_string_literal: true

class CreateCarriers < ActiveRecord::Migration[7.2]
  def change
    create_table :military_carriers do |t|
      t.string :name
      t.string :model
      t.integer :capacity

      t.timestamp :created_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.timestamp :updated_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end

    create_table :military_carrier_tags do |t|
      t.string :name
    end

    create_table :military_carrier_taggings do |t|
      t.column :taggable_id, :bigint, null: false, index: true # Change to :uuid if you are using UUIDs
      t.foreign_key :military_carriers, column: :taggable_id
      t.bigint :tag_id, null: false, index: true
      t.foreign_key :military_carrier_tags, column: :tag_id
      t.string :context, null: false
    end
  end
end
