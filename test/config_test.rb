# frozen_string_literal: true

require 'test_helper'

module NoFlyList
  class ConfigTest < ActiveSupport::TestCase
    include NoFlyList::TestHelper

    test 'has correct tag contexts configured' do
      config = Passenger._no_fly_list

      assert_equal %i[special_needs meal_preferences excuses].sort,
                   config.tag_contexts.keys.sort
    end

    test 'special_needs context has correct configuration' do
      context = Passenger._no_fly_list.tag_contexts[:special_needs]

      assert_equal 'Passenger', context[:taggable_class]
      assert_equal 'PassengerTag', context[:tag_class_name]
      assert_equal 'Passenger::Tagging', context[:tagging_class_name]
      assert_equal 'ApplicationTagTransformer', context[:transformer]
      refute context[:polymorphic]
      refute context[:restrict_to_existing]
      assert_nil context[:limit]
    end

    test 'meal_preferences context has correct configuration' do
      context = Passenger._no_fly_list.tag_contexts[:meal_preferences]

      assert_equal 'Passenger', context[:taggable_class]
      assert_equal 'PassengerTag', context[:tag_class_name]
      assert_equal 'Passenger::Tagging', context[:tagging_class_name]
      assert_equal 'ApplicationTagTransformer', context[:transformer]
      refute context[:polymorphic]
      assert context[:restrict_to_existing]
      assert_nil context[:limit]
    end

    test 'excuses context has correct global configuration' do
      context = Passenger._no_fly_list.tag_contexts[:excuses]

      assert_equal 'Passenger', context[:taggable_class]
      assert_equal 'ApplicationTag', context[:tag_class_name]
      assert_equal 'ApplicationTagging', context[:tagging_class_name]
      assert_equal 'ApplicationTagTransformer', context[:transformer]
      assert context[:polymorphic]
      refute context[:restrict_to_existing]
      assert_nil context[:limit]
    end

    test 'all tag associations are properly set up' do
      passenger = Passenger.new

      # Test special needs associations
      assert_respond_to passenger, :special_needs_list
      assert_respond_to passenger, :special_needs_list=
      assert_respond_to passenger, :special_needs
      assert_respond_to passenger, :special_need_taggings

      # Test meal preferences associations
      assert_respond_to passenger, :meal_preferences_list
      assert_respond_to passenger, :meal_preferences_list=
      assert_respond_to passenger, :meal_preferences
      assert_respond_to passenger, :meal_preference_taggings

      # Test excuses associations (global)
      assert_respond_to passenger, :excuses_list
      assert_respond_to passenger, :excuses_list=
      assert_respond_to passenger, :excuses
      assert_respond_to passenger, :excuse_taggings
    end

    test "doesn't allow non-existing meal preferences" do
      passenger = Passenger.new
      passenger.meal_preferences_list = ['imaginary_diet']

      refute passenger.valid?
      assert_includes passenger.errors.full_messages.to_sentence,
                      'imaginary_diet'
    end

    test 'allows creative excuses globally' do
      passenger = Passenger.new
      excuse = 'My pet unicorn ate my boarding pass'

      passenger.excuses_list = [excuse]
      assert passenger.valid?
      passenger.save!

      # Should use global tag table
      assert_equal Rails.application.config.no_fly_list.tag_class_name.constantize,
                   passenger.excuses.first.class
    end

    test 'saves special needs without restrictions' do
      passenger = Passenger.new
      need = 'needs_time_machine_parking'

      passenger.special_needs_list = [need]
      assert passenger.valid?
      passenger.save!

      # Should create tag in passenger-specific table
      assert_equal 'PassengerTag', passenger.special_needs.first.class.name
    end
  end
end
