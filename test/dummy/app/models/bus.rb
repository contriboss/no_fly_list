# frozen_string_literal: true

# == Schema Information
#
# Table name: buses
#
#  id           :bigint           not null, primary key
#  accessible   :boolean
#  capacity     :integer
#  company      :string(255)
#  route_number :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Bus < SecondaryRecord
  include NoFlyList::TaggableRecord

  has_tags :colors, limit: 3
end
