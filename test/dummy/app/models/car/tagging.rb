# frozen_string_literal: true

# == Schema Information
#
# Table name: car_taggings
#
#  id          :bigint           not null, primary key
#  context     :string(255)      not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  tag_id      :bigint           not null
#  taggable_id :bigint           not null
#
# Indexes
#
#  index_car_taggings_on_tag_id                  (tag_id)
#  index_car_taggings_on_taggable_id             (taggable_id)
#  index_car_taggings_on_taggable_id_and_tag_id  (taggable_id,tag_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tag_id => car_tags.id)
#  fk_rails_...  (taggable_id => cars.id)
#
class Car::Tagging < SecondaryRecord
  belongs_to :taggable, class_name: 'Car', foreign_key: 'taggable_id'
  belongs_to :tag, class_name: 'CarTag'
  include NoFlyList::TaggingRecord
end
