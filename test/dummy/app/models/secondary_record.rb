# frozen_string_literal: true

class SecondaryRecord < ActiveRecord::Base
  self.abstract_class = true

  # Establish connection to the secondary_migrate database
  connects_to database: { writing: :secondary, reading: :secondary }
end
