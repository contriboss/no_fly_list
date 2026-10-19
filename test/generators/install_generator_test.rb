# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/no_fly_list/install_generator"

class NoFlyList::Generators::InstallGeneratorTest < Rails::Generators::TestCase
  tests NoFlyList::Generators::InstallGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  test "generates application tag model" do
    run_generator

    assert_file "app/models/application_tag.rb" do |content|
      assert_match(/class ApplicationTag < ApplicationRecord/, content)
      assert_match(/include NoFlyList::ApplicationTag/, content)
    end
  end

  test "generates application tagging model" do
    run_generator

    assert_file "app/models/application_tagging.rb" do |content|
      assert_match(/class ApplicationTagging < ApplicationRecord/, content)
      assert_match(/include NoFlyList::ApplicationTagging/, content)
    end
  end

  test "generates migration" do
    run_generator

    assert_migration "db/migrate/create_application_tagging_table.rb" do |content|
      assert_match(/class CreateApplicationTaggingTable/, content)
      assert_match(/create_table :application_tags/, content)
      assert_match(/create_table :application_taggings/, content)
      assert_match(/t\.references :tag, null: false/, content)
      assert_match(/t\.references :taggable, polymorphic: true/, content)
      assert_match(/t\.string :context, null: false/, content)
    end
  end

  test "generates a unique name index without a scope" do
    run_generator

    assert_migration "db/migrate/create_application_tagging_table.rb" do |content|
      assert_match(/t\.string :name, null: false, index: \{ unique: true \}/, content)
      assert_no_match(/t\.column :\w+_id/, content)
    end
  end

  test "generates a scope column and a per-scope name index with --scope" do
    run_generator [ "--scope=entity" ]

    assert_migration "db/migrate/create_application_tagging_table.rb" do |content|
      assert_match(/t\.column :entity_id, :bigint, null: false/, content)
      assert_match(/t\.string :name, null: false\n/, content)
      assert_match(/t\.index %i\[entity_id name\], unique: true/, content)
    end
  end

  test "generates with custom connection name" do
    run_generator [ "secondary" ]

    assert_file "app/models/application_tag.rb" do |content|
      # Should use SecondaryRecord for secondary connection
      assert_match(/class ApplicationTag < SecondaryRecord/, content)
    end
  end

  private

  def prepare_destination
    destination_root = Rails.root.join("tmp/generators")
    FileUtils.rm_rf(destination_root)
    FileUtils.mkdir_p(destination_root)
    FileUtils.mkdir_p(File.join(destination_root, "app/models"))
    FileUtils.mkdir_p(File.join(destination_root, "db/migrate"))
  end
end
