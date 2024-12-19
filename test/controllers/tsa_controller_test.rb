# frozen_string_literal: true

require "test_helper"

class TsaControllerTest < ActionDispatch::IntegrationTest
  # Using passengers fixture from the provided YAML
  fixtures :passengers

  test "index returns success and data contains expected passengers" do
    get tsa_index_path
    assert_response :success
    data = response.parsed_body["data"]
    assert_not_empty data, "Data should not be empty"

    passenger_ids = passengers(:john_doe, :jane_smith, :xenu_follower, :olga_ivanova).map(&:id)
    returned_ids = data.map { |passenger| passenger["id"] }
    passenger_ids.each do |id|
      assert_includes returned_ids, id, "Data should include passenger with id #{id}"
    end
  end

  test "show returns success for existing passenger" do
    john_doe = passengers(:john_doe)

    get tsa_path(john_doe.id)
    assert_response :success
    data = response.parsed_body["data"]
    assert_equal john_doe.id, data["id"], "Returned data should match requested passenger"
  end

  test "set special needs and meal preferences" do
    jane_smith = passengers(:jane_smith)
    special_needs = "wheelchair,visual assistance"
    meal_preferences = [ "vegetarian" ]

    post set_tsa_path(jane_smith.id), params: { passenger: {
      set_special_needs: special_needs,
      set_meal_preferences: meal_preferences
    } }

    assert_response :success
    data = response.parsed_body["data"]
    assert_equal special_needs, data["special_needs"], "Special needs should be updated"
    assert_equal meal_preferences, data["meal_preferences"], "Meal preferences should be updated"
  end

  test "appends to special needs and meal preferences" do
    john_doe = passengers(:john_doe)
    additional_special_needs = "hearing assistance"
    additional_meal_preferences = "vegan"

    john_doe.special_needs_list.add!("wheelchair")
    john_doe.meal_preferences_list.add!("vegetarian")

    post append_tsa_path(john_doe.id), params: { passenger: {
      add_special_needs: additional_special_needs,
      add_meal_preferences: additional_meal_preferences
    } }

    assert_response :success
    data = response.parsed_body["data"]
    assert_includes "wheelchair,hearing assistance", data["special_needs"], "Special needs should include added values"
    assert_equal %w[vegetarian vegan].sort, data["meal_preferences"].sort,
                 "Meal preferences should include added values"
  end

  test "add and then remove specific special needs and meal preferences" do
    olga_ivanova = passengers(:olga_ivanova)
    initial_special_needs = "wheelchair, visual assistance"
    initial_meal_preferences = %w[vegetarian gluten-free]

    # First, add the needs and preferences
    post append_tsa_path(olga_ivanova.id), params: { passenger: {
      add_special_needs: initial_special_needs,
      add_meal_preferences: initial_meal_preferences
    } }

    # Then remove them
    remove_special_needs = "wheelchair"
    remove_meal_preferences = "vegetarian"

    delete remove_tsa_path(olga_ivanova.id), params: { passenger: {
      remove_special_needs: remove_special_needs,
      remove_meal_preferences: remove_meal_preferences
    } }

    assert_response :success
    data = response.parsed_body["data"]
    assert_not_includes data["special_needs"], remove_special_needs, "Special needs should not include removed values"
    assert_not_includes data["meal_preferences"], remove_meal_preferences,
                    "Meal preferences should not include removed values"
  end

  test "destroy clears all special needs and meal preferences" do
    xenu_follower = passengers(:xenu_follower)
    initial_special_needs = "intergalactic travel"
    initial_meal_preferences = [ "alien cuisine" ]

    # Add special needs and meal preferences first
    post append_tsa_path(xenu_follower.id), params: { passenger: {
      add_special_needs: initial_special_needs,
      add_meal_preferences: initial_meal_preferences
    } }

    # Check they are added
    delete tsa_path(xenu_follower.id)
    assert_response :success
    data = response.parsed_body["data"]
    assert_empty data["special_needs"], "All special needs should be cleared"
    assert_empty data["meal_preferences"], "All meal preferences should be cleared"
  end
end
