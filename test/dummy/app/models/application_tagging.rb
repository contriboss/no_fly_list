# frozen_string_literal: true

# == Schema Information
#
# Table name: application_taggings
#
#  id            :integer          not null, primary key
#  context       :string           not null
#  taggable_type :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  tag_id        :bigint           not null
#  taggable_id   :integer          not null
#
# Indexes
#
#  index_application_taggings_on_taggable  (taggable_type,taggable_id)
#
# Foreign Keys
#
#  tag_id  (tag_id => application_tags.id)
#
class ApplicationTagging < ApplicationRecord
  include NoFlyList::ApplicationTagging
end
