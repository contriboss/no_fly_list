# frozen_string_literal: true

class CreateApplicationTaggingTable < ActiveRecord::Migration[7.2]
  def up
    create_table :application_tags do |t|
      t.string :name
      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end

    create_table :application_taggings do |t|
      t.bigint :tag_id, null: false
      t.foreign_key :application_tags, column: :tag_id
      t.references :taggable, polymorphic: true, null: false
      t.string :context, null: false
      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end
  end
end
