# frozen_string_literal: true

# == Schema Information
#
# Table name: trucks
#
#  id            :integer          not null, primary key
#  capacity_tons :integer
#  driver_name   :string
#  make          :string
#  model         :string
#  year          :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Truck < SecondaryRecord
  include NoFlyList::TaggableRecord

  has_tags :cargo_types, :route_tags
end
