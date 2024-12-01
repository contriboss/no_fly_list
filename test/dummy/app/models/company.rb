# frozen_string_literal: true

# == Schema Information
#
# Table name: companies
#
#  id           :integer          not null, primary key
#  ceo_name     :string
#  founded_year :integer
#  industry     :string
#  name         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Company < ApplicationRecord
  include NoFlyList::TaggableRecord

  has_tags :industries, transformer: 'CompanyTagTransformer'
end
