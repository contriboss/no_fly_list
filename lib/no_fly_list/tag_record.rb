# frozen_string_literal: true

module NoFlyList
  # This module provides functionality for a tag table that contains tags for a model.
  #
  # @example Usage
  #   class User::Tag < ApplicationRecord
  #     include NoFlyList::TagRecord
  #   end
  module TagRecord
    extend ActiveSupport::Concern

    included do
      delegate :to_s, to: :name
      alias_attribute :tag_name, :name
      def inspect
        "#<#{self.class.name} id: #{id}, name: #{name} >"
      end
    end
  end
end
