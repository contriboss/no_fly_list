# frozen_string_literal: true

# == Schema Information
#
# Table name: truck_taggings
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
#  index_truck_taggings_on_tag_id                  (tag_id)
#  index_truck_taggings_on_taggable_id             (taggable_id)
#  index_truck_taggings_on_taggable_id_and_tag_id  (taggable_id,tag_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (tag_id => truck_tags.id)
#  fk_rails_...  (taggable_id => trucks.id)
#
class Truck::Tagging < SecondaryRecord
  self.table_name = "truck_taggings"

  belongs_to :taggable, class_name: "Truck", foreign_key: "taggable_id"
  belongs_to :tag, class_name: "TruckTag"
  include NoFlyList::TaggingRecord
end
