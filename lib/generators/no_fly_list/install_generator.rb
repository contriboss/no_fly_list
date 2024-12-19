# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"
require "rails/generators/named_base"

# Usage:
# bin/rails generate no_fly_list:application_tag

module NoFlyList
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("templates", __dir__)

      argument :connection_name, type: :string, desc: "The name of the database connection", default: "primary"

      def copy_application_tag
        ensure_connection_exists
        template "application_tag.rb.erb", File.join("app/models", "application_tag.rb")
        template "application_tagging.rb.erb", File.join("app/models", "application_tagging.rb")
        migration_template "create_application_tagging_table.rb.erb", "db/migrate/create_application_tagging_table.rb"
      end

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      private

      def ensure_connection_exists
        connection_db_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).find do |config|
          config.name == connection_name
        end
        return if connection_db_config

        say "Connection '#{connection_name}' does not exist. Please provide a valid connection name."
      end

      def connection_abstract_class_name
        # should be abstract class name
        ActiveRecord::Base.descendants.find do |klass|
          klass.abstract_class? && klass.connection_db_config.name == connection_name
        end.name
      end

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end
    end
  end
end
