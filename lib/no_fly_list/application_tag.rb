# frozen_string_literal: true

module NoFlyList
  # This module provides functionality for global tags.
  # Only one instance of this tag is allowed per database/schema.
  #
  # This concern can be included in models that represent global tags to ensure uniqueness across the database/schema.
  #
  # @example Usage
  #   class ApplicationTag < ApplicationRecord
  #     include NoFlyList::ApplicationTag
  #   end
  module ApplicationTag
    extend ActiveSupport::Concern
  end
end
