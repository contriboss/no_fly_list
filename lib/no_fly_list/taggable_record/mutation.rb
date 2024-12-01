# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    module Mutation
      module_function

      def define_mutation_methods(setup)
        context = setup.context
        taggable_klass = setup.taggable_klass

        taggable_klass.class_eval do
          # Add multiple tags
          define_method "add_#{context}" do |*tags|
            send("#{context}_list").add(*tags)
          end
          alias_method "add_#{context}=", "add_#{context}"

          # Remove multiple tags
          define_method "remove_#{context}" do |*tags|
            send("#{context}_list").remove(*tags)
          end
          alias_method "remove_#{context}=", "remove_#{context}"

          # Set tags (replaces existing)
          define_method "set_#{context}" do |*tags|
            send("#{context}_list=", tags)
          end
          alias_method "set_#{context}=", "set_#{context}"

          # Clear all tags
          define_method "clear_#{context}" do
            send("#{context}_list").clear
          end

          define_method "clear_#{context}!" do
            send("#{context}_list").clear!
          end
        end
      end
    end
  end
end
