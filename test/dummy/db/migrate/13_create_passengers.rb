# frozen_string_literal: true

class CreatePassengers < ActiveRecord::Migration[7.2]
  def change
    create_table :passengers do |t|
      t.string :first_name
      t.string :last_name
      t.string :passport_number
      t.string :nationality
      t.string :religion, default: 'scientology'
      t.string :gender, default: 'not_sure'
      t.timestamp :created_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
      t.timestamp :updated_at, default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end
  end
end
