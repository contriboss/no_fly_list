# frozen_string_literal: true

require 'active_record'
require 'active_support'
require 'active_support/rails'
require 'active_support/core_ext/numeric/time'
require_relative 'no_fly_list/version'
require 'no_fly_list/railtie' if defined?(Rails)
require 'ostruct'

module NoFlyList
  extend ActiveSupport::Autoload
  # Global tagging tables
  autoload :ApplicationTag
  autoload :ApplicationTagging

  # Common tagging tables
  autoload :TaggableRecord
  autoload_under 'taggable_record' do
    autoload :Configuration
  end
  autoload :TaggingRecord
  autoload :TagRecord

  autoload :TaggingProxy

  autoload :TestHelper
end
