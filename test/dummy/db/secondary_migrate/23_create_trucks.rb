# frozen_string_literal: true

class CreateTrucks < ActiveRecord::Migration[7.2]
  def change
    create_table :trucks do |t|
      t.string :make
      t.string :model
      t.integer :year
      t.integer :capacity_tons
      t.string :driver_name

      t.timestamp :created_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.timestamp :updated_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
  end
end
