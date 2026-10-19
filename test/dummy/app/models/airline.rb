# frozen_string_literal: true

# == Schema Information
#
# Table name: airlines
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Airline < ApplicationRecord
  has_many :crew_members
end
