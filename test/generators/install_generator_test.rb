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
    FileUtils.mkdir_p(destination_root)
    FileUtils.mkdir_p(File.join(destination_root, "app/models"))
    FileUtils.mkdir_p(File.join(destination_root, "db/migrate"))
  end
end
