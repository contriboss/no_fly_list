# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/no_fly_list/tagging_generator"

class NoFlyList::Generators::TaggingGeneratorTest < Rails::Generators::TestCase
  tests NoFlyList::Generators::TaggingGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  test "generates migration for existing model" do
    run_generator [ "Person" ]

    assert_migration "db/migrate/create_tagging_person.rb" do |content|
      assert_match(/class CreateTaggingPerson/, content)
      assert_match(/create_table :person_tags/, content)
      assert_match(/create_table :person_taggings/, content)
      assert_match(/t\.column :tag_id, :bigint, null: false/, content)
      assert_match(/t\.column :taggable_id, :bigint, null: false/, content)
      assert_match(/t\.string :context, null: false/, content)
      assert_match(/add_foreign_key :person_taggings, :person_tags/, content)
      assert_match(/add_foreign_key :person_taggings, :people/, content)
    end
  end

  test "fails for non-existent model" do
    assert_raises(ArgumentError, /Model 'NonExistentModel' does not exist/) do
      run_generator [ "NonExistentModel" ]
    end
  end

  private

  def prepare_destination
    destination_root = Rails.root.join("tmp/generators")
    FileUtils.mkdir_p(destination_root)
    FileUtils.mkdir_p(File.join(destination_root, "db/migrate"))
  end
end
