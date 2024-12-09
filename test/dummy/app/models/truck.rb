# frozen_string_literal: true

# == Schema Information
#
# Table name: trucks
#
#  id            :bigint           not null, primary key
#  capacity_tons :integer
#  driver_name   :string(255)
#  make          :string(255)
#  model         :string(255)
#  year          :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Truck < SecondaryRecord
  include NoFlyList::TaggableRecord

  has_tags :cargo_types, :route_tags
end
