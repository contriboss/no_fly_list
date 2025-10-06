# frozen_string_literal: true

require_relative "../dummy/test/test_helper"
require "no_fly_list/test_helper"

class PolymorphicTaggingTest < ActiveSupport::TestCase
  include NoFlyList::TestHelper

  setup do
    @passenger = Passenger.create!(
      first_name: "John",
      last_name: "Doe"
    )
  end

  teardown do
    # Clear in proper order to avoid foreign key constraint violations
    ApplicationTagging.delete_all
    ApplicationTag.delete_all
    Passenger.delete_all
  rescue ActiveRecord::InvalidForeignKey
    # If foreign key constraints prevent deletion, use destroy_all
    ApplicationTagging.destroy_all
    ApplicationTag.destroy_all
    Passenger.destroy_all
  end

  test "can set and retrieve polymorphic tags" do
    @passenger.excuses_list = ["weather", "maintenance", "crew shortage"]
    @passenger.save!

    assert_equal 3, @passenger.excuses_list.count
    assert_includes @passenger.excuses_list, "weather"
    assert_includes @passenger.excuses_list, "maintenance"
    assert_includes @passenger.excuses_list, "crew shortage"
  end

  test "can read existing polymorphic tags from database" do
    # Create tags directly in database
    tag1 = ApplicationTag.create!(name: "technical issue")
    tag2 = ApplicationTag.create!(name: "overbooking")

    ApplicationTagging.create!(
      tag: tag1,
      taggable: @passenger,
      context: "excuse"
    )
    ApplicationTagging.create!(
      tag: tag2,
      taggable: @passenger,
      context: "excuse"
    )

    # Reload passenger and check tags
    @passenger.reload
    excuses = @passenger.excuses_list.to_a

    assert_equal 2, excuses.count
    assert_includes excuses, "technical issue"
    assert_includes excuses, "overbooking"
  end

  test "polymorphic tags work with SQLite" do
    skip unless @passenger.class.connection.adapter_name.downcase == "sqlite"

    @passenger.excuses_list = ["delayed", "cancelled"]
    @passenger.save!

    # This should not raise "ambiguous column name" error
    assert_nothing_raised do
      excuses = @passenger.excuses_list.to_a
      assert_equal 2, excuses.count
    end
  end

  test "polymorphic tags don't interfere with non-polymorphic tags" do
    # Set non-polymorphic tags (special_needs doesn't have restrict_to_existing)
    @passenger.special_needs_list = ["wheelchair"]
    @passenger.dietary_requirements_list = ["lactose_free"]

    # Set polymorphic tags
    @passenger.excuses_list = ["security delay"]

    @passenger.save!

    assert_equal ["wheelchair"], @passenger.special_needs_list.to_a
    assert_equal ["lactose_free"], @passenger.dietary_requirements_list.to_a
    assert_equal ["security delay"], @passenger.excuses_list.to_a
  end

  test "can query records with polymorphic tags" do
    @passenger.excuses_list = ["weather", "strike"]
    @passenger.save!

    passenger2 = Passenger.create!(first_name: "Jane", last_name: "Doe")
    passenger2.excuses_list = ["weather", "mechanical"]
    passenger2.save!

    # Find passengers with weather excuse
    passengers_with_weather = Passenger.with_any_excuses("weather")
    assert_equal 2, passengers_with_weather.count

    # Find passengers with strike excuse
    passengers_with_strike = Passenger.with_any_excuses("strike")
    assert_equal 1, passengers_with_strike.count
    assert_equal @passenger.id, passengers_with_strike.first.id
  end

  test "polymorphic tags maintain uniqueness per record" do
    # Test that setting duplicate tags results in unique tags only
    @passenger.excuses_list = ["weather", "weather", "strike"]
    @passenger.save!

    # Reload to get fresh data from database
    @passenger.reload
    excuses = @passenger.excuses_list.to_a.sort

    assert_equal 2, excuses.count
    assert_includes excuses, "weather"
    assert_includes excuses, "strike"
  end
end