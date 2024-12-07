# frozen_string_literal: true

module NoFlyList
  # This module provides functionality for global tags.
  # Only one instance of this tag is allowed per database/schema.
  #
  # This concern can be included in models that represent global tags to ensure uniqueness across the database/schema.
  #
  # @example Usage
  #   class ApplicationTagging < ApplicationRecord
  #     include NoFlyList::ApplicationTagging
  #   end
  module ApplicationTagging
    extend ActiveSupport::Concern

    included do
      self.table_name = Rails.configuration.no_fly_list.application_tagging_table_name || 'application_taggings'

      belongs_to :tag, class_name: 'ApplicationTag', foreign_key: 'tag_id'
      belongs_to :taggable, polymorphic: true
    end
  end
end
