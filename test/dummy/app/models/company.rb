# frozen_string_literal: true

# == Schema Information
#
# Table name: companies
#
#  id           :bigint           not null, primary key
#  ceo_name     :string(255)
#  founded_year :integer
#  industry     :string(255)
#  name         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
class Company < ApplicationRecord
  include NoFlyList::TaggableRecord

  has_tags :industries, transformer: 'CompanyTagTransformer'
end
