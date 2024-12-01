# frozen_string_literal: true

# == Schema Information
#
# Table name: passengers
#
#  id              :integer          not null, primary key
#  first_name      :string
#  gender          :string           default("not_sure")
#  last_name       :string
#  nationality     :string
#  passport_number :string
#  religion        :string           default("scientology")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Passenger < ApplicationRecord
  include NoFlyList::TaggableRecord

  has_tags :special_needs
  has_tags :meal_preferences, restrict_to_existing: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def to_h
    {
      id: id,
      first_name: first_name,
      last_name: last_name,
      special_needs: special_needs_list.to_s,
      meal_preferences: meal_preferences_list.to_a
    }
  end
end
