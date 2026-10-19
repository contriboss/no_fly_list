# frozen_string_literal: true

class CreateCrewMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :airlines do |t|
      t.string :name, null: false
      t.timestamp :created_at, null: false
      t.timestamp :updated_at, null: false
    end

    create_table :crew_members do |t|
      t.references :airline, null: false, foreign_key: true
      t.string :name
      t.timestamp :created_at, null: false
      t.timestamp :updated_at, null: false
    end
  end
end
