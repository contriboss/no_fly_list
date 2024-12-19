# frozen_string_literal: true

module NoFlyList
  # Provides tag table functionality for models
  # Handles tag attributes and delegation of methods
  #
  # @example Usage
  #   class User::Tag < ApplicationRecord
  #     include NoFlyList::TagRecord
  #   end
  module TagRecord
    extend ActiveSupport::Concern

    included do
      # @!method to_s
      #   @return [String] String representation of tag name
      # @!method inspect
      delegate :to_s, to: :name
      alias_attribute :tag_name, :name
      def inspect
        "#<#{self.class.name} id: #{id}, name: #{name} >"
      end
    end
  end
end
