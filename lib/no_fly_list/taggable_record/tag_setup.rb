# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    class TagSetup
      attr_reader :taggable_klass, :context, :transformer, :global,
                  :restrict_to_existing, :limit,
                  :tag_class_name,
                  :tagging_class_name

      def initialize(taggable_klass, context, options = {})
        @taggable_klass = taggable_klass
        @context = context
        @transformer = options.fetch(:transformer, ApplicationTagTransformer)
        @global = options.fetch(:global, false)
        @restrict_to_existing = options.fetch(:restrict_to_existing, false)
        @limit = options.fetch(:limit, nil)
        @tag_class_name = determine_tag_class_name(taggable_klass, options)
        @tagging_class_name = determine_tagging_class_name(taggable_klass, options)
      end

      private

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
    end
  end
end
