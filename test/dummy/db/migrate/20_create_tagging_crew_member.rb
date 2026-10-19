# frozen_string_literal: true

class CreateTaggingCrewMember < ActiveRecord::Migration[7.2]
  def change
    create_table :crew_member_tags, id: :bigint do |t|
      t.column :airline_id, :bigint, null: false
      t.string :name, null: false
      t.timestamp :created_at, null: false
      t.timestamp :updated_at, null: false
    end

    create_table :crew_member_taggings do |t|
      t.column :taggable_id, :bigint, null: false, index: true
      t.column :tag_id, :bigint, null: false, index: true
      t.string :context, null: false
      t.timestamp :created_at, null: false
      t.timestamp :updated_at, null: false
    end

    add_index :crew_member_tags, %i[airline_id name], unique: true
    add_index :crew_member_taggings, %i[taggable_id tag_id], unique: true
    add_foreign_key :crew_member_taggings, :crew_member_tags, column: :tag_id
    add_foreign_key :crew_member_taggings, :crew_members, column: :taggable_id
  end
end
