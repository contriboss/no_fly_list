# frozen_string_literal: true

# == Schema Information
#
# Table name: people
#
#  id         :bigint           not null, primary key
#  address    :text(65535)
#  birthdate  :date
#  email      :string(255)
#  first_name :string(255)
#  last_name  :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Person < ApplicationRecord
  include NoFlyList::TaggableRecord

  has_tags :pronouns, restrict_to_existing: true, limit: 2, transformer: PersonTagTransformer
end
