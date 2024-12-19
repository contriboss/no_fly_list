# frozen_string_literal: true

# == Schema Information
#
# Table name: truck_tags
#
#  id         :bigint           not null, primary key
#  name       :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_truck_tags_on_name  (name) UNIQUE
#
class TruckTag < SecondaryRecord
  has_many :taggings, class_name: "Truck::Tagging", dependent: :destroy
  has_many :taggables, through: :taggings, source: :taggable, source_type: "Truck"
  include NoFlyList::TagRecord
end
