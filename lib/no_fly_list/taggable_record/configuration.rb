# frozen_string_literal: true

require_relative 'mutation'
require_relative 'query'
require_relative 'tag_setup'

module NoFlyList
  module TaggableRecord
    # Configuration module handles the setup and structure of tagging functionality
    # This includes creating necessary classes, setting up associations, and defining
    # the interface for tag manipulation
    module Configuration
      module_function

      # Main entry point for setting up tagging functionality on a model
      # @param taggable_klass [Class] The model class to make taggable
      # @param contexts [Array<Symbol>] The contexts to create tags for (e.g., :tags, :colors)
      # @param options [Hash] Configuration options for tagging behavior
      def setup_tagging(taggable_klass, contexts, options = {})
        contexts.each do |context|
          setup = build_tag_setup(taggable_klass, context, options)
          define_tag_structure(setup)
          define_list_methods(setup)
          Mutation.define_mutation_methods(setup)
          Query.define_query_methods(setup)
        end
      end

      # Creates a new TagSetup instance with the given configuration
      def build_tag_setup(taggable_klass, context, options)
        TagSetup.new(taggable_klass, context, options)
      end

      # Determines the appropriate class name for tags based on configuration
      # For global tags, uses application-wide tag class
      # For local tags, creates model-specific tag classes
      def determine_tag_class_name(taggable_klass, options)
        if options[:polymorphic]
          Rails.application.config.no_fly_list.tag_class_name
        else
          options.fetch(:tag_class_name, "#{taggable_klass.name}Tag")
        end
      end

      # Determines the appropriate class name for taggings based on configuration
      # For global tags, uses application-wide tagging class
      # For local tags, creates model-specific tagging classes
      def determine_tagging_class_name(taggable_klass, options)
        if options[:polymorphic]
          Rails.application.config.no_fly_list.tagging_class_name
        else
          options.fetch(:tagging_class_name, "#{taggable_klass.name}::Tagging")
        end
      end

      # Sets up the complete tag structure including classes and associations
      def define_tag_structure(setup)
        define_tag_classes(setup) unless setup.polymorphic
        define_tagging_associations(setup)
      end

      # Creates the tag and tagging classes for local (non-global) tags
      def define_tag_classes(setup)
        base_class = find_abstract_class(setup.taggable_klass)

        define_constant_in_namespace(setup.tag_class_name) do
          create_tag_class(setup, base_class)
        end

        define_constant_in_namespace(setup.tagging_class_name) do
          create_tagging_class(setup, base_class)
        end
      end

      # Creates a new tag class with appropriate configuration
      def create_tag_class(setup, base_class)
        Class.new(base_class) do
          self.table_name = "#{setup.taggable_klass.table_name.singularize}_tags"
          include NoFlyList::TagRecord
        end
      end

      # Creates a new tagging class with appropriate configuration
      def create_tagging_class(setup, base_class)
        setup.context.to_s.singularize

        Class.new(base_class) do
          self.table_name = "#{setup.taggable_klass.table_name.singularize}_taggings"

          # Add the basic associations
          belongs_to :tag,
                     class_name: setup.tag_class_name,
                     foreign_key: 'tag_id'

          belongs_to :taggable,
                     class_name: setup.taggable_klass.name,
                     foreign_key: 'taggable_id'

          include NoFlyList::TaggingRecord
        end
      end

      # Sets up all necessary associations between tags, taggings, and the taggable model
      def define_tagging_associations(setup)
        singular_name = setup.context.to_s.singularize

        if setup.polymorphic
          setup_polymorphic_tag_associations(setup, singular_name)
        else
          setup_local_tag_associations(setup, singular_name)
        end

        setup_taggable_associations(setup, singular_name)
      end

      # Sets up associations for polymorphic tags
      def setup_polymorphic_tag_associations(setup, singular_name)
        # Set up the tag model associations
        setup.tag_class_name.constantize.class_eval do
          # Fix: Use 'tagging' for the join association when context is 'tag'
          association_name = (singular_name == 'tag' ? :taggings : :"#{singular_name}_taggings")

          has_many association_name,
                   -> { where(context: singular_name) },
                   class_name: setup.tagging_class_name,
                   foreign_key: 'tag_id',
                   dependent: :destroy

          # Fix: Use consistent naming for through association
          has_many setup.context,
                   through: association_name,
                   source: :taggable,
                   source_type: setup.taggable_klass.name
        end

        # Set up the tagging model with global scope
        setup.tagging_class_name.constantize.class_eval do
          belongs_to :tag,
                     class_name: setup.tag_class_name,
                     foreign_key: 'tag_id'

          belongs_to :taggable,
                     polymorphic: true

          validates :tag, :taggable, :context, presence: true

          # Add scope for specific taggable type
          scope :for_taggable_type, ->(type) { where(taggable_type: type) }

          validates :tag_id, uniqueness: {
            scope: %i[taggable_type taggable_id context],
            message: 'has already been tagged on this record in this context'
          }
        end
      end

      # Sets up associations for local (non-global) tags
      def setup_local_tag_associations(setup, singular_name)
        # Set up tag class associations
        setup.tag_class_name.constantize.class_eval do
          has_many :"#{singular_name}_taggings",
                   -> { where(context: singular_name) },
                   class_name: setup.tagging_class_name,
                   foreign_key: 'tag_id',
                   dependent: :destroy

          has_many :"#{singular_name}_taggables",
                   through: :"#{singular_name}_taggings",
                   source: :taggable
        end

        # Set up tagging class associations
        setup.tagging_class_name.constantize.class_eval do
          belongs_to :tag,
                     class_name: setup.tag_class_name,
                     foreign_key: 'tag_id'

          # For local tags, we use a simple belongs_to without polymorphic
          belongs_to :taggable,
                     class_name: setup.taggable_klass.name,
                     foreign_key: 'taggable_id'

          validates :tag, :taggable, :context, presence: true
          validates :tag_id, uniqueness: {
            scope: %i[taggable_id context],
            message: 'has already been tagged on this record in this context'
          }
        end
      end

      # Sets up associations on the taggable model
      def setup_taggable_associations(setup, singular_name)
        setup.taggable_klass.class_eval do
          if setup.polymorphic
            # Global tags need polymorphic associations
            has_many :"#{singular_name}_taggings",
                     -> { where(context: singular_name) },
                     class_name: setup.tagging_class_name,
                     foreign_key: 'taggable_id',
                     as: :taggable,
                     dependent: :destroy

            has_many setup.context,
                     through: :"#{singular_name}_taggings",
                     source: :tag,
                     class_name: setup.tag_class_name do
              def by_type(taggable_type)
                where(taggings: { taggable_type: taggable_type })
              end

              def shared_with(other_taggable)
                where(id: other_taggable.send(proxy_association.name).pluck(:id))
              end
            end
          else
            # Local tags should use simple associations
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
      end

      def define_list_methods(setup)
        context = setup.context
        taggable_klass = setup.taggable_klass

        # Define helper methods module for this context
        helper_module = Module.new do
          define_method :create_and_set_proxy do |instance_variable_name, setup|
            tag_model = if setup.polymorphic
                          setup.tag_class_name.constantize
                        else
                          self.class.const_get("#{self.class.name}Tag")
                        end

            proxy = TaggingProxy.new(
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
