# frozen_string_literal: true

# == Schema Information
#
# Table name: military_carriers
#
#  id         :bigint           not null, primary key
#  capacity   :integer
#  model      :string(255)
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
module Military
  class Carrier < ApplicationRecord
    include NoFlyList::TaggableRecord

    has_tags :mission_types, :capabilities, :notable_features
  end
end
