# frozen_string_literal: true

require_relative 'mutation'
require_relative 'query'

module NoFlyList
  module TaggableRecord
    module Configuration
      module_function

      def setup_tagging(taggable_klass, contexts, options = {})
        contexts.each do |context|
          setup = build_tag_setup(taggable_klass, context, options)
          define_tag_structure(setup)
          define_list_methods(setup)
          Mutation.define_mutation_methods(setup) # Add mutation methods
          Query.define_query_methods(setup) # Add query methods
        end
      end

      def build_tag_setup(taggable_klass, context, options)
        OpenStruct.new(
          taggable_klass: taggable_klass,
          context: context,
          transformer: options.fetch(:transformer, ApplicationTagTransformer),
          global: options.fetch(:global, false),
          restrict_to_existing: options.fetch(:restrict_to_existing, false),
          limit: options.fetch(:limit, nil),
          tag_class_name: determine_tag_class_name(taggable_klass, options),
          tagging_class_name: determine_tagging_class_name(taggable_klass, options)
        )
      end

      def determine_tag_class_name(taggable_klass, options)
        if options[:global]
          Rails.application.config.no_fly_list.tag_class_name
        else
          options.fetch(:tag_class_name, "#{taggable_klass.name}Tag")
        end
      end

      def determine_tagging_class_name(taggable_klass, options)
        if options[:global]
          Rails.application.config.no_fly_list.tagging_class_name
        else
          options.fetch(:tagging_class_name, "#{taggable_klass.name}::Tagging")
        end
      end

      def define_tag_structure(setup)
        define_tag_classes(setup) unless setup.global
        define_tagging_associations(setup)
      end

      def define_tag_classes(setup)
        base_class = find_abstract_class(setup.taggable_klass)

        define_constant_in_namespace(setup.tag_class_name) do
          create_tag_class(setup, base_class)
        end

        define_constant_in_namespace(setup.tagging_class_name) do
          create_tagging_class(setup, base_class)
        end
      end

      def create_tag_class(setup, base_class)
        Class.new(base_class) do
          self.table_name = "#{setup.taggable_klass.table_name.singularize}_tags"

          has_many :taggings, class_name: setup.tagging_class_name, dependent: :destroy
          has_many :taggables, through: :taggings, source: :taggable, source_type: setup.taggable_klass.name
          include NoFlyList::TagRecord
        end
      end

      def create_tagging_class(setup, base_class)
        Class.new(base_class) do
          self.table_name = "#{setup.taggable_klass.table_name.singularize}_taggings"

          belongs_to :taggable, class_name: setup.taggable_klass.name, foreign_key: 'taggable_id'
          belongs_to :tag, class_name: setup.tag_class_name
          include NoFlyList::TaggingRecord
        end
      end

      def define_tagging_associations(setup)
        singular_name = setup.context.to_s.singularize

        setup.taggable_klass.class_eval do
          has_many :"#{singular_name}_taggings",
                   -> { where(context: singular_name) },
                   class_name: setup.tagging_class_name,
                   foreign_key: 'taggable_id',
                   dependent: :destroy

          has_many setup.context,
                   through: :"#{singular_name}_taggings",
                   source: :tag,
                   class_name: setup.tag_class_name
        end
      end

      def define_list_methods(setup)
        context = setup.context
        taggable_klass = setup.taggable_klass

        # Define helper methods module for this context
        helper_module = Module.new do
          define_method :create_and_set_proxy do |instance_variable_name, setup|
            tag_model = if setup.global
                          setup.tag_class_name.constantize
                        else
                          self.class.const_get("#{self.class.name}Tag")
                        end

            proxy = NoFlyList::TaggingProxy.new(
              self,
              tag_model,
              setup.context,
              transformer: setup.transformer,
              restrict_to_existing: setup.restrict_to_existing,
              limit: calculate_limit(setup.limit)
            )
            instance_variable_set(instance_variable_name, proxy)
          end

          define_method :calculate_limit do |limit|
            limit.is_a?(Proc) ? limit.call(self) : limit
          end

          define_method :reset_proxy_for do |context|
            instance_variable_name = "@_#{context}_list_proxy"
            remove_instance_variable(instance_variable_name) if instance_variable_defined?(instance_variable_name)
          end
        end

        # Include the helper methods
        taggable_klass.include(helper_module)

        # Define the public interface methods
        taggable_klass.class_eval do
          define_method "#{context}_list" do
            instance_variable_name = "@_#{context}_list_proxy"

            if instance_variable_defined?(instance_variable_name)
              instance_variable_get(instance_variable_name)
            else
              create_and_set_proxy(instance_variable_name, setup)
            end
          end

          define_method "#{context}_list=" do |tag_list|
            reset_proxy_for(context)
            proxy = send("#{context}_list")
            proxy.send("#{context}_list=", tag_list)
          end

          define_method "reset_#{context}_list" do
            reset_proxy_for(context)
          end
        end
      end

      def find_abstract_class(klass)
        while klass && !klass.abstract_class?
          klass = klass.superclass
          break if klass == ActiveRecord::Base || klass.nil?
        end
        klass || ActiveRecord::Base
      end

      def define_constant_in_namespace(const_name)
        parts = const_name.split('::')
        const_name = parts.pop
        namespace = parts.join('::').safe_constantize || Object
        return if namespace.const_defined?(const_name, false)

        namespace.const_set(const_name, yield)
      end
    end
  end
end
