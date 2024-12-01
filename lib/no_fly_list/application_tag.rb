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

    included do
      self.table_name = Rails.configuration.no_fly_list.application_tag_table_name || 'application_tags'

      has_many :taggings, class_name: 'ApplicationTagging', dependent: :destroy, foreign_key: 'tag_id'
      has_many :taggables, through: :taggings, source: :taggable
    end
  end
end
