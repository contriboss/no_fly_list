# frozen_string_literal: true

class CreateCars < ActiveRecord::Migration[7.2]
  def change
    create_table :cars do |t|
      t.string :make
      t.string :model
      t.integer :year
      t.string :color
      t.integer :price_cents

      t.timestamp :created_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.timestamp :updated_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
  end
end
