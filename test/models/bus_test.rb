# frozen_string_literal: true

require 'test_helper'

class BusTest < ActiveSupport::TestCase
  include NoFlyList::TestHelper
  fixtures :buses
  # Test associations for colors
  should have_many(:color_taggings)
  should have_many(:colors).through(:color_taggings)

  test 'assert_taggable_record' do
    assert_taggable_record(Bus, :colors)
  end

  test 'test limit with number' do
    bus = buses(:city_express)
    bus.colors_list = %w[red green blue]
    bus.colors_list.save
    assert_equal 3, bus.colors_list.count

    bus2 = buses(:metro_transit)
    bus2.colors_list = %w[red green blue yellow]
    proxy = bus2.colors_list
    proxy.save

    assert_not proxy.valid?
    assert_includes proxy.errors.full_messages, 'Cannot have more than 3 tags (attempting to save 4)'
    assert_equal 0, bus2.colors_list.count
  end
end
