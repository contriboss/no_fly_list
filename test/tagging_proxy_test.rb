# frozen_string_literal: true

require "test_helper"

class TaggingProxyTest < ActiveSupport::TestCase
  def setup
    @car = Car.create!(make: "Toyota", model: "Corolla")
  end

  def test_add_tags
    @car.colors_list.add("red, blue")
    assert_equal [ "red", "blue" ], @car.colors_list.to_a
  end

  def test_remove_tags
    @car.colors_list.add("red, blue")
    @car.colors_list.remove("red")
    assert_equal [ "blue" ], @car.colors_list.to_a
  end

  def test_clear_tags
    @car.colors_list.add("red, blue")
    @car.colors_list.clear
    assert_equal [], @car.colors_list.to_a
  end

  def test_include_tag
    @car.colors_list.add("red, blue")
    assert @car.colors_list.include?("red")
    assert_not @car.colors_list.include?("green")
  end

  def test_empty_tags
    assert @car.colors_list.empty?
    @car.colors_list.add("red")
    assert_not @car.colors_list.empty?
  end

  def test_add_tags!
    @car.colors_list.clear
    @car.colors_list.add!("red, blue")
    assert_equal [ "red", "blue" ], @car.colors_list.to_a
  end

  def test_remove_tags!
    @car.colors_list.clear
    @car.colors_list.add!("red, blue")
    @car.colors_list.remove!("red")
    assert_equal [ "blue" ], @car.colors_list.to_a
  end

  def test_clear_tags!
    @car.colors_list.add!("red, blue")
    @car.colors_list.clear!
    assert_equal [], @car.colors_list.to_a
  end

  def test_add_tags_as_array
    @car.colors_list.add([ "red", "blue" ])
    @car.colors_list.add([ "green", "yellow" ])
    assert_equal [ "red", "blue", "green", "yellow" ], @car.colors_list.to_a

    @car.colors_list.remove([ "red", "blue", "green" ])
    assert_equal [ "yellow" ], @car.colors_list.to_a
  end
end
