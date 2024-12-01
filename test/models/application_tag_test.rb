# frozen_string_literal: true

require 'test_helper'
class ApplicationTagTest < ActiveSupport::TestCase
  should have_many(:taggings)
end
