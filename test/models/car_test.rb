# frozen_string_literal: true

require 'test_helper'

class CarTest < ActiveSupport::TestCase
  fixtures :cars
  include NoFlyList::TestHelper

  def setup
    @tesla = cars(:tesla)    # Melon Musk's favorite ride
    @jaguar = cars(:jaguar)  # The woke Jaguar
    @lada = cars(:lada)      # In Soviet Russia, car tests you!
  end

  # Basic taggable tests
  test 'check if model is taggable' do
    assert_taggable_record Car, :colors, :fuel_types
  end

  test 'should have proper tag associations' do
    assert_respond_to @tesla, :colors
    assert_respond_to @tesla, :fuel_types

    # Tag list methods - don't exhaust yourself!
    assert_respond_to @tesla, :colors_list
    assert_respond_to @tesla, :fuel_types_list
  end

  test 'should paint the town red (or any color really)' do
    @tesla.colors_list = ['cherry_red']
    assert @tesla.save
    @tesla.reload

    assert_equal ['cherry_red'], @tesla.colors_list.to_a
  end

  test 'should fuel our imagination with multiple tags' do
    @tesla.colors_list = ['metallic_blue']
    @tesla.fuel_types_list = ['electrons'] # Tesla's favorite food!
    assert @tesla.save!
    @tesla.reload

    assert_equal ['metallic_blue'], @tesla.colors_list.to_a
    assert_equal ['electrons'], @tesla.fuel_types_list.to_a
  end

  test 'should find cars faster than you can say vrooom' do
    # Color some cars with style
    @tesla.colors_list = ['rainbow']
    assert @tesla.save

    @jaguar.colors_list = ['miami pink', 'london blue']
    assert @jaguar.save

    # Rev up those queries!
    rainbow_rides = Car.with_any_colors('rainbow')
    spotted_speedsters = Car.with_any_colors('miami pink')

    assert_includes rainbow_rides, @tesla, 'Looks like our Tesla lost its colors in space!'
    assert_includes spotted_speedsters, @jaguar, 'The woke Jaguar is missing - maybe it got ordinary deleted?'
  end
end
