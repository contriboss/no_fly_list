# frozen_string_literal: true

require "test_helper"

class CounterCacheTest < ActiveSupport::TestCase
  fixtures :passengers
  include NoFlyList::TestHelper

  def test_multiple_counters_increment
    passenger = passengers(:john_doe)
    assert_equal 0, passenger.special_needs_count
    assert_equal 0, passenger.dietary_requirements_count

    passenger.special_needs_list.add("wheelchair")
    passenger.dietary_requirements_list.add("halal")
    passenger.save!
    passenger.reload

    assert_equal 1, passenger.special_needs_count
    assert_equal 1, passenger.dietary_requirements_count
  end

  def test_independent_counter_operations
    passenger = passengers(:jane_smith)

    passenger.special_needs_list.add("wheelchair", "service_animal")
    passenger.dietary_requirements_list.add("halal")
    passenger.save!
    passenger.reload

    assert_equal 2, passenger.special_needs_count
    assert_equal 1, passenger.dietary_requirements_count

    passenger.special_needs_list.remove("wheelchair")
    passenger.dietary_requirements_list.add("kosher")
    passenger.save!
    passenger.reload

    assert_equal 1, passenger.special_needs_count
    assert_equal 2, passenger.dietary_requirements_count
  end

  def test_clearing_specific_counter
    passenger = passengers(:olga_ivanova)

    passenger.special_needs_list.add("wheelchair")
    passenger.dietary_requirements_list.add("vegetarian", "gluten_free")
    passenger.save!
    passenger.reload

    assert_equal 1, passenger.special_needs_count
    assert_equal 2, passenger.dietary_requirements_count

    passenger.clear_dietary_requirements
    passenger.save!
    passenger.reload

    assert_equal 1, passenger.special_needs_count
    assert_equal 0, passenger.dietary_requirements_count
  end

  def test_meal_preferences_without_counter
    passenger = passengers(:xenu_follower)

    passenger.special_needs_list.add("wheelchair")
    passenger.meal_preferences_list.add("vegan")
    passenger.save!
    passenger.reload

    assert_equal 1, passenger.special_needs_count
    assert_equal false, passenger.respond_to?(:meal_preferences_count)
  end
end
