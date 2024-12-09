# frozen_string_literal: true

class CreatePeople < ActiveRecord::Migration[7.2]
  def change
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.date :birthdate
      t.string :email
      t.text :address

      t.timestamp :created_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.timestamp :updated_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end

    create_table :person_tags do |t|
      t.string :name, null: false
    end

    create_table :person_taggings do |t|
      t.bigint :tag_id, null: false
      t.foreign_key :person_tags, column: :tag_id
      t.bigint :taggable_id, null: false
      t.foreign_key :people, column: :taggable_id
      t.string :context, null: false
    end
  end
end
