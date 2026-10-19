# frozen_string_literal: true

require "forwardable"
require "rails/generators"
require "rails/generators/active_record"
require "rails/generators/named_base"

module NoFlyList
  module Generators
    class TaggingGenerator < Rails::Generators::NamedBase
      include ActiveRecord::Generators::Migration
      source_root File.expand_path("templates", __dir__)

      class_option :database, type: :string, default: "primary",
                              desc: "Use different database for migration"
      class_option :scope, type: :string,
                           desc: "belongs_to association (e.g. entity) that keeps tags unique per scope"

      def self.default_generator_root
        File.dirname(__FILE__)
      end

      def create_migration_file
        ensure_model_exists
        migration_template "create_tagging_table.rb.erb",
                           [ db_migrate_path, "create_#{migration_name}.rb" ].compact.join("/")
      end

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      private

      def ensure_model_exists
        name.constantize
      rescue NameError
        raise ArgumentError, "Model '#{name}' does not exist. Please provide a valid model name."
      end

      def migration_name
        "tagging_#{name.underscore.tr('/', '_')}"
      end

      def migration_class_name
        "CreateTagging#{name.gsub('::', '')}"
      end

      def target_class
        @target_class ||= name.constantize
      end

      def model_table_name
        target_class.table_name
      end

      def tag_table_name
        "#{model_table_name.singularize}_tags"
      end

      def tagging_table_name
        "#{model_table_name.singularize}_taggings"
      end

      # Column added to the tag table for --scope=NAME: the foreign key of the
      # model's NAME association, else NAME_id, or NAME when it ends in _id.
      def scope_column
        scope = options[:scope]
        return if scope.blank?

        reflection = target_class.reflect_on_association(scope)
        return reflection.foreign_key.to_s if reflection

        scope.end_with?("_id") ? scope : "#{scope}_id"
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end
    end
  end
end
