# frozen_string_literal: true

module NoFlyList
  # This module provides functionality for a tag table that contains global tags for a model.
  #
  # This concern can be included in models that represent tags to manage global tags across different records.
  #
  # @example Usage
  #   class User::Tag < ApplicationRecord
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
