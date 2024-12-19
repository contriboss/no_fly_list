# frozen_string_literal: true

require "forwardable"
require "rails/generators"
require "rails/generators/active_record"
require "rails/generators/named_base"

module NoFlyList
  module Generators
    class TaggingGenerator < Rails::Generators::NamedBase
      include ActiveRecord::Generators::Migration

      class_option :database, type: :string, default: "primary",
                              desc: "Use different database for migration"

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

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end
    end
  end
end
