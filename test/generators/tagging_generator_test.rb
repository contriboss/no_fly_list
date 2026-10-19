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

  test "generates a name index without a scope" do
    run_generator [ "Person" ]

    assert_migration "db/migrate/create_tagging_person.rb" do |content|
      assert_match(/add_index :person_tags, :name, unique: true/, content)
      assert_match(/create_table :person_tags, id: :bigint do \|t\|\n      t\.string :name, null: false/, content)
    end
  end

  test "generates a scope column and a per-scope name index with --scope" do
    run_generator [ "Person", "--scope=airline" ]

    assert_migration "db/migrate/create_tagging_person.rb" do |content|
      assert_match(/create_table :person_tags, id: :bigint do \|t\|\n      t\.column :airline_id, :bigint, null: false/, content)
      assert_match(/add_index :person_tags, %i\[airline_id name\], unique: true/, content)
      assert_no_match(/add_index :person_tags, :name/, content)
    end
  end

  test "uses the association foreign key for --scope" do
    run_generator [ "CrewMember", "--scope=airline" ]

    assert_migration "db/migrate/create_tagging_crew_member.rb" do |content|
      assert_match(/t\.column :airline_id, :bigint, null: false/, content)
      assert_match(/add_index :crew_member_tags, %i\[airline_id name\], unique: true/, content)
    end
  end

  test "accepts a column name for --scope" do
    run_generator [ "Person", "--scope=entity_id" ]

    assert_migration "db/migrate/create_tagging_person.rb" do |content|
      assert_match(/t\.column :entity_id, :bigint, null: false/, content)
      assert_match(/add_index :person_tags, %i\[entity_id name\], unique: true/, content)
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
    FileUtils.rm_rf(destination_root)
    FileUtils.mkdir_p(destination_root)
    FileUtils.mkdir_p(File.join(destination_root, "db/migrate"))
  end
end
