# frozen_string_literal: true

require 'test_helper'

class ApplicationTaggingTest < ActiveSupport::TestCase
  should belong_to(:tag)
  should belong_to(:taggable)
end
