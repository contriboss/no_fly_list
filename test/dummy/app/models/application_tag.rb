# frozen_string_literal: true

# == Schema Information
#
# Table name: application_tags
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class ApplicationTag < ApplicationRecord
  include NoFlyList::ApplicationTag
end
