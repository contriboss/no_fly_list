# frozen_string_literal: true

require 'test_helper'

module Military
  class CarrierTest < ActiveSupport::TestCase
    include NoFlyList::TestHelper
    fixtures 'military/carriers'
    attr_reader :enterprise

    setup do
      @enterprise = military_carriers(:uss_enterprise)
    end

    test 'assert_taggable_record' do
      assert_taggable_record(Carrier, :mission_types, :capabilities, :notable_features)
    end

    should have_many(:mission_type_taggings)
    should have_many(:mission_types).through(:mission_type_taggings)

    should have_many(:capability_taggings)
    should have_many(:capabilities).through(:capability_taggings)

    should have_many(:notable_feature_taggings)
    should have_many(:notable_features).through(:notable_feature_taggings)

    test 'add and retrieve tags' do
      # Add tags to the USS Enterprise (loaded from fixtures)
      enterprise.add_mission_types(['Flagships', 'Deep-Space Explorations'])

      enterprise.add_capabilities(['High Capacities', 'Technologically Advanced Systems'])
      enterprise.add_notable_features('Historical Significances, Time Travel Capabilities')

      # Check tag associations
      assert_equal ['Flagships', 'Deep-Space Explorations'], enterprise.mission_types_list.to_a
      assert_equal ['High Capacities', 'Technologically Advanced Systems'], enterprise.capabilities_list.to_a
      assert_equal ['Historical Significances', 'Time Travel Capabilities'], enterprise.notable_features_list.to_a
      assert_equal 'Historical Significances,Time Travel Capabilities', enterprise.notable_features_list.to_s
    end
    test 'remove tags' do
      # Add and remove tags from the USS Enterprise
      enterprise.add_mission_types(['Flagships', 'Deep-Space Explorations'])
      assert_equal ['Flagships', 'Deep-Space Explorations'], enterprise.mission_types_list.to_a

      enterprise.remove_mission_types('Flagships')
      assert_equal ['Deep-Space Explorations'], enterprise.mission_types_list.to_a
    end

    test 'set tags' do
      enterprise.add_mission_types(['Flagships', 'Deep-Space Explorations'])
      assert_equal ['Flagships', 'Deep-Space Explorations'], enterprise.mission_types_list.to_a

      enterprise.set_mission_types(['Exploratory Ships'])
      assert_equal ['Exploratory Ships'], enterprise.mission_types_list.to_a
    end

    test 'clear tags' do
      enterprise.add_mission_types(['Flagships', 'Deep-Space Explorations'])
      assert_equal ['Flagships', 'Deep-Space Explorations'], enterprise.mission_types_list.to_a

      enterprise.clear_mission_types
      assert_empty enterprise.mission_types_list.to_a
    end
  end
end
