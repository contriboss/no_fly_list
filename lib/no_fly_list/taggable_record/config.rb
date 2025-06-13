# frozen_string_literal: true

module NoFlyList
  class Config
    attr_reader :tag_contexts, :taggable_class, :adapter

    def initialize(taggable_class = nil)
      @tag_contexts = {}
      @taggable_class = taggable_class
      @adapter = determine_adapter
    end

    def add_context(context, options = {})
      context = context.to_sym
      tag_class_name = determine_tag_class_name(options)
      tagging_class_name = determine_tagging_class_name(options)

      @tag_contexts[context] = {
        taggable_class: @taggable_class.to_s,
        tag_class_name: tag_class_name,
        tagging_class_name: tagging_class_name,
        transformer: options.fetch(:transformer, "ApplicationTagTransformer").to_s,
        polymorphic: options.fetch(:polymorphic, false),
        restrict_to_existing: options.fetch(:restrict_to_existing, false),
        limit: options.fetch(:limit, nil),
        case_sensitive: options.fetch(:case_sensitive, true),
        adapter: @adapter,
        counter_cache: options.fetch(:counter_cache, false)
      }
    end

    private

    def determine_adapter
      case taggable_class.connection.adapter_name.downcase
      when "postgresql"
        :postgresql
      when "mysql2"
        :mysql
      else
        :sqlite
      end
    end

    def determine_tag_class_name(options)
      if options[:polymorphic]
        Rails.application.config.no_fly_list.tag_class_name
      else
        options.fetch(:tag_class_name, "#{@taggable_class}Tag")
      end
    end

    def determine_tagging_class_name(options)
      if options[:polymorphic]
        Rails.application.config.no_fly_list.tagging_class_name
      else
        options.fetch(:tagging_class_name, "#{@taggable_class}::Tagging")
      end
    end
  end
end
