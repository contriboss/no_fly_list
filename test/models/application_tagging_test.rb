# frozen_string_literal: true

require "test_helper"

class ApplicationTaggingTest < ActiveSupport::TestCase
  test "belongs to tag" do
    assert belong_to(:tag).matches?(ApplicationTagging.new)
  end

  test "belongs to taggable" do
    assert belong_to(:taggable).matches?(ApplicationTagging.new)
  end
end
