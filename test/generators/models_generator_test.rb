# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/no_fly_list/models_generator"

class NoFlyList::Generators::ModelsGeneratorTest < Rails::Generators::TestCase
  tests NoFlyList::Generators::ModelsGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  test "generates tag and tagging models for existing model" do
    run_generator [ "Person" ]

    assert_file "app/models/person_tag.rb" do |content|
      assert_match(/class PersonTag < ApplicationRecord/, content)
      assert_match(/include NoFlyList::TagRecord/, content)
    end

    assert_file "app/models/person/tagging.rb" do |content|
      assert_match(/class Person::Tagging < ApplicationRecord/, content)
      assert_match(/include NoFlyList::TaggingRecord/, content)
    end
  end

  test "fails for non-existent model" do
    assert_raises(ArgumentError, /NonExistentModel is not a valid constant/) do
      run_generator [ "NonExistentModel" ]
    end

    assert_no_file "app/models/non_existent_model_tag.rb"
    assert_no_file "app/models/non_existent_model/tagging.rb"
  end

  test "fails for non-ActiveRecord class" do
    # Mock a non-ActiveRecord class
    Object.const_set("TestClass", Class.new)

    assert_raises(ArgumentError, /TestClass is not an ActiveRecord model/) do
      run_generator [ "TestClass" ]
    end

    assert_no_file "app/models/test_class_tag.rb"
    assert_no_file "app/models/test_class/tagging.rb"
  ensure
    Object.send(:remove_const, "TestClass") if Object.const_defined?("TestClass")
  end

  test "generates models for namespaced class" do
    run_generator [ "Military::Carrier" ]

    assert_file "app/models/military/carrier_tag.rb" do |content|
      assert_match(/class Military::CarrierTag < ApplicationRecord/, content)
    end

    assert_file "app/models/military/carrier/tagging.rb" do |content|
      assert_match(/class Military::Carrier::Tagging < ApplicationRecord/, content)
    end
  end

  private

  def prepare_destination
    destination_root = Rails.root.join("tmp/generators")
    FileUtils.mkdir_p(destination_root)
    FileUtils.mkdir_p(File.join(destination_root, "app/models"))
  end
end
