# frozen_string_literal: true

class CreateCompanies < ActiveRecord::Migration[7.2]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :industry
      t.integer :founded_year
      t.string :ceo_name

      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }
    end
  end
end
