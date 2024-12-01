# frozen_string_literal: true

# == Schema Information
#
# Table name: car_tags
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_car_tags_on_name  (name) UNIQUE
#
class CarTag < SecondaryRecord
  has_many :taggings, class_name: 'Car::Tagging', dependent: :destroy
  has_many :taggables, through: :taggings, source: :taggable, source_type: 'Car'
  include NoFlyList::TagRecord
end
