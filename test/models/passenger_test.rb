# frozen_string_literal: true

require 'test_helper'

class PassengerTest < ActiveSupport::TestCase
  fixtures :passengers, :passenger_tags
  include NoFlyList::TestHelper
  # Test associations for special_needs
  should have_many(:special_need_taggings)
  should have_many(:special_needs).through(:special_need_taggings)

  # Test associations for meal_preferences
  should have_many(:meal_preference_taggings)
  should have_many(:meal_preferences).through(:meal_preference_taggings)

  test 'assert_taggable_record' do
    assert_taggable_record(Passenger, :special_needs, :meal_preferences)
  end

  setup do
    @john = passengers(:john_doe)
    @jane = passengers(:jane_smith)
    @xenu = passengers(:xenu_follower)
    @olga = passengers(:olga_ivanova)

    # Setup meal preferences
    @john.meal_preferences_list = %w[vegan gluten_free]
    @jane.meal_preferences_list = %w[vegetarian]
    @xenu.meal_preferences_list = %w[vegan vegetarian halal]
    @olga.meal_preferences_list = %w[kosher]

    # Setup special needs
    @john.special_needs_list = %w[wheelchair assistance]
    @jane.special_needs_list = %w[wheelchair]
    @xenu.special_needs_list = %w[translator]

    [@john, @jane, @xenu, @olga].each(&:save!)
  end

  test 'with_all_meal_preferences finds passengers with all specified diets' do
    # Should find passengers with both vegan and vegetarian preferences
    result = Passenger.with_all_meal_preferences(%w[vegan vegetarian])
    assert_equal [@xenu].to_set, result.to_set

    # Should find no passengers requiring impossible combination
    result = Passenger.with_all_meal_preferences(%w[vegan kosher])
    assert_empty result
  end

  test 'with_any_meal_preferences finds passengers with any of specified diets' do
    # Should find passengers with either vegan or vegetarian preferences
    result = Passenger.with_any_meal_preferences(%w[vegan vegetarian])
    assert_equal [@john, @jane, @xenu].to_set, result.to_set

    # Should handle single preference
    result = Passenger.with_any_meal_preferences('kosher')
    assert_equal [@olga], result.to_a
  end

  test 'without_meal_preferences finds passengers with no meal preferences' do
    @olga.clear_meal_preferences!
    result = Passenger.without_meal_preferences
    assert_equal [@olga], result.to_a
  end

  test 'without_any_meal_preferences excludes passengers with specified preferences' do
    result = Passenger.without_any_meal_preferences(%w[vegan vegetarian])
    assert_equal [@olga].to_set, result.to_set
  end

  test 'with_exact_meal_preferences finds passengers with exactly specified preferences' do
    result = Passenger.with_exact_meal_preferences(%w[vegan gluten_free])
    assert_equal [@john], result.to_a

    result = Passenger.with_exact_meal_preferences([])
    assert_empty result
  end

  test 'with_all_special_needs finds passengers with all specified needs' do
    result = Passenger.with_all_special_needs('wheelchair')
    assert_equal [@john, @jane].to_set, result.to_set

    result = Passenger.with_all_special_needs(%w[wheelchair assistance])
    assert_equal [@john].to_set, result.to_set
  end

  test 'with_any_special_needs finds passengers with any specified needs' do
    result = Passenger.with_any_special_needs(%w[wheelchair translator])
    assert_equal [@john, @jane, @xenu].to_set, result.to_set
  end

  test 'without_special_needs finds passengers with no special needs' do
    result = Passenger.without_special_needs
    assert_equal [@olga], result.to_a
  end

  test 'combining multiple tag queries' do
    # Find vegan passengers with wheelchair access
    result = Passenger
             .with_any_meal_preferences('vegan')
             .with_all_special_needs('wheelchair')
    assert_equal [@john], result.to_a
  end

  test 'querying with empty tag arrays' do
    assert_empty Passenger.with_all_meal_preferences([])
    assert_empty Passenger.with_any_meal_preferences([])
    assert_equal Passenger.all.to_set, Passenger.without_any_meal_preferences([]).to_set
  end

  test 'querying with invalid tags' do
    assert_empty Passenger.with_all_meal_preferences('nonexistent')
    assert_empty Passenger.with_any_meal_preferences('nonexistent')
    assert_equal Passenger.all.to_set, Passenger.without_any_meal_preferences('nonexistent').to_set
  end

  test 'case sensitivity in queries' do
    @john.meal_preferences_list = ['Vegan']
    @john.save!

    # Should find case-insensitive matches
    result = Passenger.with_any_meal_preferences('vegan')
    assert_includes result, @john
  end
end
