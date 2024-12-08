# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    class TagSetup
      attr_reader :taggable_klass, :context, :transformer, :polymorphic,
                  :restrict_to_existing, :limit,
                  :tag_class_name, :tagging_class_name, :adapter

      def initialize(taggable_klass, context, options = {})
        @taggable_klass = taggable_klass
        @context = context
        @transformer = options.fetch(:transformer, ApplicationTagTransformer)
        @polymorphic = options.fetch(:polymorphic, false)
        @restrict_to_existing = options.fetch(:restrict_to_existing, false)
        @limit = options.fetch(:limit, nil)
        @tag_class_name = determine_tag_class_name(taggable_klass, options)
        @tagging_class_name = determine_tagging_class_name(taggable_klass, options)
        @adapter = determine_adapter
      end

      private

      def determine_adapter
        case ActiveRecord::Base.connection.adapter_name.downcase
        when 'postgresql'
          :postgresql
        when 'mysql2'
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
