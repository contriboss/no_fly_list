# frozen_string_literal: true

class CreateBuses < ActiveRecord::Migration[7.2]
  def change
    create_table :buses do |t|
      t.string :route_number
      t.integer :capacity
      t.string :company
      t.boolean :accessible

      t.timestamp :created_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.timestamp :updated_at, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end
  end
end
