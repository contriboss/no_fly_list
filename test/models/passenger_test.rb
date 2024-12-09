# frozen_string_literal: true

require 'test_helper'

class PassengerTest < ActiveSupport::TestCase
  fixtures :passengers, :passenger_tags
  include NoFlyList::TestHelper

  # Test associations
  should have_many(:special_need_taggings)
  should have_many(:special_needs).through(:special_need_taggings)
  should have_many(:meal_preference_taggings)
  should have_many(:meal_preferences).through(:meal_preference_taggings)

  test 'assert_taggable_record' do
    assert_taggable_record(Passenger, :special_needs, :meal_preferences)
  end

  test 'test_helper' do
    assert_local_tag_classes_exist(Passenger, :special_needs)
    assert_local_tag_classes_exist(Passenger, :meadddl_preferencess)
  end

  class MealPreferenceTests < ActiveSupport::TestCase
    fixtures :passengers, :passenger_tags
    def setup
      @john = passengers(:john_doe)
      @jane = passengers(:jane_smith)
      @xenu = passengers(:xenu_follower)

      @john.meal_preferences_list = %w[vegan gluten_free]
      @jane.meal_preferences_list = %w[vegetarian]
      @xenu.meal_preferences_list = %w[vegan vegetarian halal]
      [@john, @jane, @xenu].each(&:save!)
    end

    test 'with_all_meal_preferences finds passengers with all specified diets' do
      result = Passenger.with_all_meal_preferences(%w[vegan vegetarian])
      assert_equal [@xenu].to_set, result.to_set

      result = Passenger.with_all_meal_preferences(%w[vegan kosher])
      assert_empty result
    end

    test 'with_any_meal_preferences finds passengers with any of specified diets' do
      result = Passenger.with_any_meal_preferences(%w[vegan vegetarian])
      assert_equal [@john, @jane, @xenu].to_set, result.to_set
    end

    test 'with_exact_meal_preferences finds passengers with exactly specified preferences' do
      result = Passenger.with_exact_meal_preferences(%w[vegan gluten_free])

      assert_equal 2, @john.meal_preferences_list.count
      actual_sql = result.to_sql

      expected_sql = case model_adapter(Passenger)
                     when :sqlite
                       "SELECT \"passengers\".* FROM \"passengers\" WHERE (passengers.id IN (SELECT \"passengers\".\"id\" FROM \"passengers\" INNER JOIN passenger_taggings ON passenger_taggings.taggable_id = passengers.id INNER JOIN passenger_tags ON passenger_tags.id = passenger_taggings.tag_id WHERE (passenger_taggings.context = 'meal_preference') AND (passenger_tags.name IN ('vegan', 'gluten_free')) GROUP BY \"passengers\".\"id\" HAVING (COUNT(DISTINCT passenger_tags.id) = 2))) AND (passengers.id NOT IN (SELECT \"passengers\".\"id\" FROM \"passengers\" INNER JOIN passenger_taggings ON passenger_taggings.taggable_id = passengers.id INNER JOIN passenger_tags ON passenger_tags.id = passenger_taggings.tag_id WHERE (passenger_taggings.context = 'meal_preference') AND (passenger_tags.name NOT IN ('vegan', 'gluten_free'))))"
                     when :postgresql
                       "SELECT \"passengers\".* FROM \"passengers\" WHERE (passengers.id IN (SELECT \"passengers\".\"id\" FROM \"passengers\" INNER JOIN passenger_taggings ON passenger_taggings.taggable_id = passengers.id INNER JOIN passenger_tags ON passenger_tags.id = passenger_taggings.tag_id WHERE (passenger_taggings.context = 'meal_preference') AND (passenger_tags.name IN ('vegan', 'gluten_free')) GROUP BY \"passengers\".\"id\" HAVING (COUNT(DISTINCT passenger_tags.id) = 2))) AND (passengers.id NOT IN (SELECT \"passengers\".\"id\" FROM \"passengers\" INNER JOIN passenger_taggings ON passenger_taggings.taggable_id = passengers.id INNER JOIN passenger_tags ON passenger_tags.id = passenger_taggings.tag_id WHERE (passenger_taggings.context = 'meal_preference') AND (passenger_tags.name NOT IN ('vegan', 'gluten_free'))))"
                     when :mysql2
                       "SELECT `passengers`.* FROM `passengers` WHERE (passengers.id IN (SELECT `passengers`.`id` FROM `passengers` INNER JOIN passenger_taggings ON passenger_taggings.taggable_id = passengers.id INNER JOIN passenger_tags ON passenger_tags.id = passenger_taggings.tag_id WHERE (passenger_taggings.context = 'meal_preference') AND (passenger_tags.name IN ('vegan', 'gluten_free')) GROUP BY `passengers`.`id` HAVING (COUNT(DISTINCT passenger_tags.id) = '2'))) AND (passengers.id NOT IN (SELECT `passengers`.`id` FROM `passengers` INNER JOIN passenger_taggings ON passenger_taggings.taggable_id = passengers.id INNER JOIN passenger_tags ON passenger_tags.id = passenger_taggings.tag_id WHERE (passenger_taggings.context = 'meal_preference') AND (passenger_tags.name NOT IN ('vegan', 'gluten_free'))))"
                     end

      assert_equal normalize_sql(expected_sql), normalize_sql(actual_sql)

      assert_equal [@john], result.to_a
    end

    test 'querying with empty tag arrays' do
      assert_empty Passenger.with_all_meal_preferences([])
      assert_empty Passenger.with_any_meal_preferences([])
      assert_equal Passenger.all.to_set, Passenger.without_any_meal_preferences([]).to_set
    end

    test 'case sensitivity in queries' do
      @john.meal_preferences_list = ['vegan']
      @john.save!

      result = Passenger.with_any_meal_preferences('vegan')
      assert_includes result, @john
    end
  end

  class SpecialNeedsTests < ActiveSupport::TestCase
    fixtures :passengers, :passenger_tags
    def setup
      @john = passengers(:john_doe)
      @jane = passengers(:jane_smith)
      @xenu = passengers(:xenu_follower)

      @john.special_needs_list = %w[wheelchair assistance]
      @jane.special_needs_list = %w[wheelchair]
      @xenu.special_needs_list = %w[translator]
      [@john, @jane, @xenu].each(&:save!)
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
  end

  class CombinedTagTests < ActiveSupport::TestCase
    fixtures :passengers, :passenger_tags
    def setup
      @olga = passengers(:olga_ivanova)
      @john = passengers(:john_doe)
      @jane = passengers(:jane_smith)
      @xenu = passengers(:xenu_follower)

      @john.meal_preferences_list = %w[vegan gluten_free]
      @jane.meal_preferences_list = %w[vegetarian]
      @xenu.meal_preferences_list = %w[vegan vegetarian halal]

      @john.special_needs_list = %w[wheelchair assistance]
      @jane.special_needs_list = %w[exorcism]
      @xenu.special_needs_list = %w[translator]

      [@john, @jane, @xenu].each(&:save!)

      # Assert data was saved
      assert_equal 2, @john.meal_preferences_list.count
      assert_equal 1, @jane.meal_preferences_list.count
      assert_equal 3, @xenu.meal_preferences_list.count
      assert_equal 2, @john.special_needs_list.count
      assert_equal 1, @jane.special_needs_list.count
      assert_equal 1, @xenu.special_needs_list.count
      assert_equal 0, @olga.meal_preferences_list.count
      assert_equal 0, @olga.special_needs_list.count
    end

    test 'combining multiple tag queries' do
      result = Passenger
               .with_any_meal_preferences('vegan')
               .with_all_special_needs('wheelchair')

      actual_sql = result.to_sql

      expected_sql = case model_adapter(Passenger)
                     when :sqlite
                       "SELECT \"passengers\".* FROM \"passengers\" WHERE \"passengers\".\"id\" IN (SELECT DISTINCT \"passengers\".\"id\" FROM passengers INNER JOIN \"passenger_taggings\" ON \"passenger_taggings\".\"taggable_id\" = \"passengers\".\"id\" INNER JOIN \"passenger_tags\" ON \"passenger_tags\".\"id\" = \"passenger_taggings\".\"tag_id\" WHERE \"passenger_taggings\".\"context\" = 'meal_preference' AND \"passenger_tags\".\"name\" IN ('vegan')) AND \"passengers\".\"id\" IN (SELECT \"passengers\".\"id\" FROM passengers INNER JOIN \"passenger_taggings\" ON \"passenger_taggings\".\"taggable_id\" = \"passengers\".\"id\" INNER JOIN \"passenger_tags\" ON \"passenger_tags\".\"id\" = \"passenger_taggings\".\"tag_id\" WHERE \"passenger_taggings\".\"context\" = 'special_need' AND \"passenger_tags\".\"name\" IN ('wheelchair') GROUP BY \"passengers\".\"id\" HAVING COUNT(DISTINCT(\"passenger_tags\".\"name\")) = 1)"
                     when :postgresql
                       "SELECT \"passengers\".* FROM \"passengers\" WHERE \"passengers\".\"id\" IN (SELECT DISTINCT \"passengers\".\"id\" FROM passengers INNER JOIN \"passenger_taggings\" ON \"passenger_taggings\".\"taggable_id\" = \"passengers\".\"id\" INNER JOIN \"passenger_tags\" ON \"passenger_tags\".\"id\" = \"passenger_taggings\".\"tag_id\" WHERE \"passenger_taggings\".\"context\" = 'meal_preference' AND \"passenger_tags\".\"name\" IN ('vegan')) AND \"passengers\".\"id\" IN (SELECT \"passengers\".\"id\" FROM passengers INNER JOIN \"passenger_taggings\" ON \"passenger_taggings\".\"taggable_id\" = \"passengers\".\"id\" INNER JOIN \"passenger_tags\" ON \"passenger_tags\".\"id\" = \"passenger_taggings\".\"tag_id\" WHERE \"passenger_taggings\".\"context\" = 'special_need' AND \"passenger_tags\".\"name\" IN ('wheelchair') GROUP BY \"passengers\".\"id\" HAVING COUNT(DISTINCT(\"passenger_tags\".\"name\")) = 1)"
                     when :mysql2
                       "SELECT `passengers`.* FROM `passengers` WHERE `passengers`.`id` IN (SELECT DISTINCT `passengers`.`id` FROM passengers INNER JOIN `passenger_taggings` ON `passenger_taggings`.`taggable_id` = `passengers`.`id` INNER JOIN `passenger_tags` ON `passenger_tags`.`id` = `passenger_taggings`.`tag_id` WHERE `passenger_taggings`.`context` = 'meal_preference' AND `passenger_tags`.`name` IN ('vegan')) AND `passengers`.`id` IN (SELECT `passengers`.`id` FROM passengers INNER JOIN `passenger_taggings` ON `passenger_taggings`.`taggable_id` = `passengers`.`id` INNER JOIN `passenger_tags` ON `passenger_tags`.`id` = `passenger_taggings`.`tag_id` WHERE `passenger_taggings`.`context` = 'special_need' AND `passenger_tags`.`name` IN ('wheelchair') GROUP BY `passengers`.`id` HAVING COUNT(DISTINCT(`passenger_tags`.`name`)) = 1)"
                     end
      assert_equal normalize_sql(expected_sql), normalize_sql(actual_sql)

      assert_equal [@john], result.to_a
    end

    test 'without_meal_preferences finds passengers with no meal preferences' do
      result = Passenger.without_meal_preferences

      # Capture the SQL generated
      actual_sql = result.to_sql

      # Assert the SQL structure
      expected_sql = case model_adapter(Passenger)
                     when :sqlite
                       <<-SQL
    SELECT "passengers".*
    FROM "passengers"
    WHERE (id NOT IN (
      SELECT "passenger_taggings"."taggable_id"
      FROM "passenger_taggings"
      WHERE "passenger_taggings"."context" = 'meal_preference'
    ))
                       SQL
                     when :postgresql
                       "SELECT \"passengers\".* FROM \"passengers\" WHERE \"passengers\".\"id\" NOT IN (SELECT \"passenger_taggings\".\"taggable_id\" FROM \"passenger_taggings\" WHERE \"passenger_taggings\".\"context\" = 'meal_preference')"
                     when :mysql2
                       "SELECT `passengers`.* FROM `passengers` WHERE (passengers.id NOT IN (SELECT `passenger_taggings`.`taggable_id` FROM `passenger_taggings` WHERE `passenger_taggings`.`context` = 'meal_preference'))"
                     end

      assert_equal normalize_sql(expected_sql), normalize_sql(actual_sql)

      # Assert the result
      assert_equal [@olga], result.to_a
    end

    test 'without_special_needs finds passengers with no special needs' do
      result = Passenger.without_special_needs

      actual_sql = Passenger.without_special_needs.to_sql

      expected_sql = case model_adapter(Passenger)
                     when :sqlite
                       <<-SQL
    SELECT "passengers".*
    FROM "passengers"
    WHERE (id NOT IN (
      SELECT "passenger_taggings"."taggable_id"
      FROM "passenger_taggings"
      WHERE "passenger_taggings"."context" = 'special_need'
    ))
                       SQL
                     when :postgresql
                       "SELECT \"passengers\".* FROM \"passengers\" WHERE \"passengers\".\"id\" NOT IN (SELECT \"passenger_taggings\".\"taggable_id\" FROM \"passenger_taggings\" WHERE \"passenger_taggings\".\"context\" = 'special_need')"
                     when :mysql2
                       "SELECT `passengers`.* FROM `passengers` WHERE (passengers.id NOT IN (SELECT `passenger_taggings`.`taggable_id` FROM `passenger_taggings` WHERE `passenger_taggings`.`context` = 'special_need'))"
                     end

      assert_equal normalize_sql(expected_sql), normalize_sql(actual_sql)

      assert_equal [@olga], result.to_a
    end
  end
end
