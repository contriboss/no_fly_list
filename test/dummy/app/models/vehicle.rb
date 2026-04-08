# frozen_string_literal: true

# == Schema Information
#
# Table name: vehicles
#
#  id         :bigint           not null, primary key
#  type       :string(255)      not null
#  name       :string(255)
#  year       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Vehicle < ApplicationRecord
  include NoFlyList::TaggableRecord

  has_tags :features
end
