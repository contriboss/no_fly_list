# frozen_string_literal: true

# == Schema Information
#
# Table name: people
#
#  id         :integer          not null, primary key
#  address    :text
#  birthdate  :date
#  email      :string
#  first_name :string
#  last_name  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Person < ApplicationRecord
  include NoFlyList::TaggableRecord

  has_tags :pronouns, restrict_to_existing: true, limit: 2, transformer: PersonTagTransformer
end
