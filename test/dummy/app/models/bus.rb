# frozen_string_literal: true

# == Schema Information
#
# Table name: buses
#
#  id           :integer          not null, primary key
#  accessible   :boolean
#  capacity     :integer
#  company      :string
#  route_number :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Bus < SecondaryRecord
  include NoFlyList::TaggableRecord

  has_tags :colors, limit: 3
end
