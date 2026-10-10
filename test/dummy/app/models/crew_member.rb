# frozen_string_literal: true

# == Schema Information
#
# Table name: crew_members
#
#  id         :bigint           not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  airline_id :bigint           not null
#
class CrewMember < ApplicationRecord
  include NoFlyList::TaggableRecord

  belongs_to :airline

  # Each airline keeps its own vocabulary of crew tags
  has_tags :skills, scope: :airline
  has_tags :roles, scope: :airline, case_sensitive: false
  has_tags :languages, scope: :airline, restrict_to_existing: true, case_sensitive: false
  has_tags :certifications, polymorphic: true, scope: :airline, case_sensitive: false
end
