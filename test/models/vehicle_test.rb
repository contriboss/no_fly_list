# frozen_string_literal: true

require "test_helper"

class VehicleTest < ActiveSupport::TestCase
  include NoFlyList::TestHelper

  fixtures :vehicles, :vehicle_tags

  # Base class tagging
  test "assert_taggable_record for Vehicle" do
    assert_taggable_record(Vehicle, :features)
  end

  test "assert_taggable_record for Bicycle" do
    assert_taggable_record(Bicycle, :features)
    assert_taggable_record(Bicycle, :terrain_types)
  end

  test "assert_taggable_record for Motorcycle" do
    assert_taggable_record(Motorcycle, :features)
    assert_taggable_record(Motorcycle, :engine_types)
  end

  # STI subclass tagging
  test "bicycle can have terrain_types tags" do
    bike = vehicles(:road_bike)
    assert_instance_of Bicycle, bike

    bike.terrain_types_list.add("road", "gravel")
    assert bike.terrain_types_list.save

    assert_equal 2, bike.terrain_types_list.count
    assert_includes bike.terrain_types_list.to_a, "road"
    assert_includes bike.terrain_types_list.to_a, "gravel"
  end

  test "motorcycle can have engine_types tags" do
    moto = vehicles(:harley)
    assert_instance_of Motorcycle, moto

    moto.engine_types_list.add("v-twin")
    assert moto.engine_types_list.save

    assert_equal 1, moto.engine_types_list.count
    assert_includes moto.engine_types_list.to_a, "v-twin"
  end

  test "both STI subclasses share features from base class" do
    bike = vehicles(:mountain_bike)
    moto = vehicles(:ducati)

    bike.features_list.add("lightweight", "carbon fiber")
    assert bike.features_list.save

    moto.features_list.add("electric", "lightweight")
    assert moto.features_list.save

    assert_equal 2, bike.features_list.count
    assert_equal 2, moto.features_list.count

    # Both share the "lightweight" tag but are independent records
    assert_includes bike.features_list.to_a, "lightweight"
    assert_includes moto.features_list.to_a, "lightweight"
  end

  test "STI subclass tags are scoped to their context" do
    bike = vehicles(:road_bike)
    moto = vehicles(:harley)

    # Bicycle has terrain_types but not engine_types
    assert_respond_to bike, :terrain_types_list
    assert_not_respond_to bike, :engine_types_list

    # Motorcycle has engine_types but not terrain_types
    assert_respond_to moto, :engine_types_list
    assert_not_respond_to moto, :terrain_types_list
  end

  test "tags persist correctly across STI type column" do
    bike = vehicles(:road_bike)
    bike.features_list.add("electric")
    assert bike.features_list.save

    # Reload via base class and verify STI type is preserved
    reloaded = Vehicle.find(bike.id)
    assert_instance_of Bicycle, reloaded
    assert_equal ["electric"], reloaded.features_list.to_a
  end
end
