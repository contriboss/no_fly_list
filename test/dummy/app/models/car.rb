# frozen_string_literal: true

# == Schema Information
#
# Table name: cars
#
#  id          :bigint           not null, primary key
#  color       :string(255)
#  make        :string(255)
#  model       :string(255)
#  price_cents :integer
#  year        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Car < SecondaryRecord
  include NoFlyList::TaggableRecord

  has_tags :colors, :fuel_types
end
