# frozen_string_literal: true

# == Schema Information
#
# Table name: passengers
#
#  id              :bigint           not null, primary key
#  first_name      :string(255)
#  gender          :string(255)      default("not_sure")
#  last_name       :string(255)
#  nationality     :string(255)
#  passport_number :string(255)
#  religion        :string(255)      default("scientology")
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Passenger < ApplicationRecord
  include NoFlyList::TaggableRecord

  has_tags :special_needs, counter_cache: true
  has_tags :meal_preferences, restrict_to_existing: true
  has_tags :dietary_requirements, counter_cache: true

  # We add creative excuses to not let the passenger board the plane
  has_tags :excuses, polymorphic: true

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
