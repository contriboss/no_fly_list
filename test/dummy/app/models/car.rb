# frozen_string_literal: true

# == Schema Information
#
# Table name: cars
#
#  id          :integer          not null, primary key
#  color       :string
#  make        :string
#  model       :string
#  price_cents :integer
#  year        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Car < SecondaryRecord
  include NoFlyList::TaggableRecord

  has_tags :tags, global: true
end
