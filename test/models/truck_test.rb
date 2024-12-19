# frozen_string_literal: true

require "test_helper"

class TruckTest < ActiveSupport::TestCase
  include NoFlyList::TestHelper
  fixtures :trucks
  test "test Truck and its associations" do
    assert_taggable_record(Truck, :cargo_types, :route_tags)
  end

  should have_many(:cargo_type_taggings)
  should have_many(:cargo_types).through(:cargo_type_taggings)

  should have_many(:route_tag_taggings)
  should have_many(:route_tags).through(:route_tag_taggings)

  test "manage cargo and route tags" do
    truck = trucks(:big_hauler)

    # Add and manage cargo tags using bang methods
    truck.cargo_types_list = "hazardous_material, refrigerated_goods"
    truck.cargo_types_list.save
    assert_equal 2, truck.cargo_types_list.count

    truck.cargo_types_list.add!("oversized_loads")
    assert_equal 3, truck.cargo_types_list.count

    truck.cargo_types_list.remove!("refrigerated_goods")
    assert_equal 2, truck.cargo_types_list.count

    truck.cargo_types_list.clear!
    assert_equal 0, truck.cargo_types_list.count

    # Route Tags
    truck.route_tags_list = "long_haul, interstate"
    assert_equal 0, truck.route_tags.count
    assert_equal 2, truck.route_tags_list.size

    truck.route_tags_list.add("local_delivery")
    assert_equal 0, truck.route_tags.count
    assert_equal 3, truck.route_tags_list.size

    truck.route_tags_list.remove("interstate")
    assert_equal 0, truck.route_tags.count
    assert_equal 2, truck.route_tags_list.size

    truck.route_tags_list.save
    assert_equal 2, truck.route_tags.count

    truck.route_tags_list.clear
    assert_equal 2, truck.route_tags.count
    truck.route_tags_list.save
  end
end
