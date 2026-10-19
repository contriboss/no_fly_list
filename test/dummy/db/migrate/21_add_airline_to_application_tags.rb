# frozen_string_literal: true

# Scopes the global tags so CrewMember can use polymorphic tags per airline.
# The column stays nullable because Passenger keeps unscoped global tags.
class AddAirlineToApplicationTags < ActiveRecord::Migration[7.2]
  def change
    add_column :application_tags, :airline_id, :bigint
    remove_index :application_tags, :name, unique: true
    add_index :application_tags, %i[airline_id name], unique: true
  end
end
