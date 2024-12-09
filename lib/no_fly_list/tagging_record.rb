# frozen_string_literal: true

module NoFlyList
  # This module provides functionality for a tagging table that contains tags relationship for a model.
  #
  # This concern can be included in models that represent tags to manage the relationship between the tag and the model.
  #
  # @example Usage
  #   class User::Tagging < ApplicationRecord
  #     include NoFlyList::TaggingModel
  #   end
  module TaggingRecord
    extend ActiveSupport::Concern

    delegate :tag_name, to: :tag

    def inspect
      "#<#{self.class.name} id: #{id}, tag_name: #{tag_name} >"
    end
  end
end
