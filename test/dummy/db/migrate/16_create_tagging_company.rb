# frozen_string_literal: true

class CreateTaggingCompany < ActiveRecord::Migration[7.2]
  def change
    create_table :company_tags, id: :bigint do |t|
      t.string :name, null: false
      t.timestamp :created_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp :updated_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end

    create_table :company_taggings do |t|
      t.column :taggable_id, :bigint, null: false, index: true # Change to :uuid if you are using UUIDs
      t.column :tag_id, :bigint, null: false, index: true
      t.string :context, null: false
      t.timestamp :created_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp :updated_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end

    add_index :company_tags, :name, unique: true
    add_index :company_taggings, %i[taggable_id tag_id], unique: true
    add_foreign_key :company_taggings, :company_tags, column: :tag_id
    add_foreign_key :company_taggings, :companies, column: :taggable_id
  end
end
