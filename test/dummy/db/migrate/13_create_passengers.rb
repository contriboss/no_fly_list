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
      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end
  end
end
