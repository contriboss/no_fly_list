# frozen_string_literal: true

require "test_helper"

class TaggingProxyTest < ActiveSupport::TestCase
  def setup
    @person = Person.create!(first_name: "John", last_name: "Doe")
  end

  def test_add_tags
    @person.pronouns_list.add("he/ him")
    assert_equal ["he", "him"], @person.pronouns_list.to_a
  end

  def test_remove_tags
    @person.pronouns_list.add("he/ him")
    @person.pronouns_list.remove("he")
    assert_equal ["him"], @person.pronouns_list.to_a
  end

  def test_clear_tags
    @person.pronouns_list.add("he/ him")
    @person.pronouns_list.clear
    assert_equal [], @person.pronouns_list.to_a
  end

  def test_include_tag
    @person.pronouns_list.add("he/ him")
    assert @person.pronouns_list.include?("he")
    assert_not @person.pronouns_list.include?("she")
  end

  def test_empty_tags
    assert @person.pronouns_list.empty?
    @person.pronouns_list.add("he")
    assert_not @person.pronouns_list.empty?
  end

  def test_add_tags!
    @person.pronouns_list.clear
    @person.pronouns_list.add!("he/ him")
    assert_equal ["he", "him"], @person.pronouns_list.to_a
  end

  def test_remove_tags!
    @person.pronouns_list.clear
    @person.pronouns_list.add!("he/ him")
    @person.pronouns_list.remove!("he")
    assert_equal ["him"], @person.pronouns_list.to_a
  end

  def test_clear_tags!
    @person.pronouns_list.add!("he/ him")
    @person.pronouns_list.clear!
    assert_equal [], @person.pronouns_list.to_a
  end
end