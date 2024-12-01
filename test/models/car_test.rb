# frozen_string_literal: true

require 'test_helper'

class CarTest < ActiveSupport::TestCase
  include NoFlyList::TestHelper
  # Test associations for tags
  should have_many(:tag_taggings)
  should have_many(:tags).through(:tag_taggings)

  test 'check if model is taggable' do
    assert_taggable_record Car, :tags
  end
end
