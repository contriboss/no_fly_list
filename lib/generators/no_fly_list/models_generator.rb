# frozen_string_literal: true

require "forwardable"
require "rails/generators"
require "rails/generators/active_record"
require "rails/generators/named_base"

module NoFlyList
  module Generators
    class ModelsGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_model_files
        return unless validate_model # Ensure it's an ActiveRecord model

        template "tagging_model.rb.erb", File.join("app/models", class_path, "#{file_name.underscore}/tagging.rb")
        template "tag_model.rb.erb", File.join("app/models", class_path, "#{file_name.underscore}_tag.rb")
      end

      private

      def model_class
        @model_class ||= class_name.constantize
      end
      alias taggable_klass class_name

      def tag_class_name
        "#{class_name}Tag"
      end

      def tagging_class_name
        "#{class_name}::Tagging"
      end

      def validate_model
        if model_class < ActiveRecord::Base
          true
        else
          raise ArgumentError, "#{class_name} is not an ActiveRecord model. Aborting generator."
        end
      rescue NameError
        raise ArgumentError, "#{class_name} is not a valid constant. Aborting generator."
      end

      def model_abstract_class_name
        klass = model_class.ancestors.find do |ancestor|
          ancestor.is_a?(Class) && ancestor.abstract_class?
        end
        klass&.name || "ApplicationRecord"
      end
    end
  end
end
