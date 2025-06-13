# frozen_string_literal: true

require "test_helper"
require "rails/generators/test_case"
require "generators/no_fly_list/transformer_generator"

class NoFlyList::Generators::TransformerGeneratorTest < Rails::Generators::TestCase
  tests NoFlyList::Generators::TransformerGenerator
  destination Rails.root.join("tmp/generators")
  setup :prepare_destination

  test "generates application tag transformer" do
    run_generator

    assert_file "app/transformers/application_tag_transformer.rb" do |content|
      assert_match(/module ApplicationTagTransformer/, content)
      assert_match(/module_function/, content)
      assert_match(/def parse_tags\(tags\)/, content)
      assert_match(/def recreate_string\(tags\)/, content)
      assert_match(/def separator/, content)
      assert_match(/tags\.split\(separator\)/, content)
      assert_match(/tags\.join\(separator\)/, content)
    end
  end

  test "creates transformers directory if it doesn't exist" do
    run_generator

    assert_directory "app/transformers"
  end

  private

  def prepare_destination
    destination_root = Rails.root.join("tmp/generators")
    FileUtils.mkdir_p(destination_root)
  end
end
