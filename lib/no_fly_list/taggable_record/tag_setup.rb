# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    # Handles setup and configuration of tagging for a model
    class TagSetup
      # @return [Class] Model class being made taggable
      attr_reader :taggable_klass

      # @return [Symbol] Tagging context name
      attr_reader :context

      # @return [Class] Tag string transformer
      attr_reader :transformer

      # @return [Boolean] Whether tags are polymorphic
      attr_reader :polymorphic

      # @return [Boolean] Whether to restrict to existing tags
      attr_reader :restrict_to_existing

      # @return [Integer, nil] Maximum number of tags allowed
      attr_reader :limit

      # @return [Boolean] Whether to use counter cache
      attr_reader :counter_cache

      # @return [String] Name of tag class
      attr_reader :tag_class_name

      # @return [String] Name of tagging class
      attr_reader :tagging_class_name

      # @return [Symbol] Database adapter type (:postgresql, :mysql, :sqlite)
      attr_reader :adapter

      # @return [Symbol, nil] belongs_to association (or column) that partitions tags
      attr_reader :scope

      # @return [Boolean] Whether tag names are compared case sensitively
      attr_reader :case_sensitive

      # Creates new tag setup configuration
      # @param taggable_klass [Class] Model to configure
      # @param context [Symbol] Tag context name
      # @param options [Hash] Setup options
      def initialize(taggable_klass, context, options = {})
        @taggable_klass = taggable_klass
        @context = context
        @transformer = options.fetch(:transformer, "ApplicationTagTransformer")
        @polymorphic = options.fetch(:polymorphic, false)
        @restrict_to_existing = options.fetch(:restrict_to_existing, false)
        @counter_cache = options.fetch(:counter_cache, false)
        @counter_cache_column = "#{context}_count"
        @limit = options.fetch(:limit, nil)
        @tag_class_name = determine_tag_class_name(taggable_klass, options)
        @tagging_class_name = determine_tagging_class_name(taggable_klass, options)
        @adapter = determine_adapter
        @scope = options[:scope]
        @case_sensitive = options.fetch(:case_sensitive, true)
      end

      # Column shared by the taggable and tag tables that keeps tags unique per
      # scope: the foreign key of the +scope+ association, or +scope+ itself
      # when no such association exists. Resolved on first use so +has_tags+
      # may be declared before the association.
      # @return [String, nil] Scope column name, or nil for unscoped tags
      def scope_column
        return unless scope

        @scope_column ||= begin
          reflection = taggable_klass.reflect_on_association(scope)
          if reflection&.polymorphic?
            raise ArgumentError, "NoFlyList: scope #{scope.inspect} on #{taggable_klass.name} is a polymorphic association, which is not supported"
          end

          reflection ? reflection.foreign_key.to_s : scope.to_s
        end
      end

      private

      def determine_adapter
        case ActiveRecord::Base.connection.adapter_name.downcase
        when "postgresql"
          :postgresql
        when "mysql2"
          :mysql
        else
          :sqlite
        end
      end

      def determine_tag_class_name(taggable_klass, options)
        if options[:polymorphic]
          Rails.application.config.no_fly_list.tag_class_name
        else
          options.fetch(:tag_class_name, "#{taggable_klass.name}Tag")
        end
      end

      def determine_tagging_class_name(taggable_klass, options)
        if options[:polymorphic]
          Rails.application.config.no_fly_list.tagging_class_name
        else
          options.fetch(:tagging_class_name, "#{taggable_klass.name}::Tagging")
        end
      end
    end
  end
end
