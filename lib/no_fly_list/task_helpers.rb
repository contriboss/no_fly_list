# frozen_string_literal: true

module NoFlyList
  module TaskHelpers
    COLORS = {
      mysql2: "\e[38;5;33m",
      postgresql: "\e[38;5;31m",
      sqlite: "\e[38;5;245m",
      reset: "\e[0m",
      green: "\e[32m",
      red: "\e[31m",
      yellow: "\e[33m"
    }.freeze

    REQUIRED_COLUMNS = {
      tag: [ "name" ],
      tagging: %w[tag_id taggable_id context]
    }.freeze

    def self.adapter_color(klass)
      color_key = klass.connection.adapter_name.downcase.to_sym
      COLORS[color_key] || COLORS[:sqlite]
    end

    def self.colorize(text, color)
      "#{COLORS[color]}#{text}#{COLORS[:reset]}"
    end

    def self.check_table(klass)
      klass.table_exists?
      [ true, "#{colorize('✓', :green)} Table exists: #{klass.table_name}" ]
    rescue StandardError => e
      [ false, "#{colorize('✗', :red)} Error: #{e.message}" ]
    end

    def self.verify_columns(klass, type)
      return unless klass.table_exists?

      existing_columns = klass.column_names
      required_columns = REQUIRED_COLUMNS[type]
      missing_columns = required_columns - existing_columns

      if missing_columns.empty?
        "#{colorize('✓', :green)} Required columns present"
      else
        "#{colorize('!', :yellow)} Missing required columns: #{missing_columns.join(', ')}"
      end
    end

    def self.format_columns(klass)
      return unless klass.table_exists?
      "#{colorize('✓', :green)} All columns: #{klass.column_names.join(', ')}"
    end

    def self.check_class(class_name)
      Object.const_get(class_name)
    rescue NameError
      nil
    end

    def self.find_taggable_classes
      Rails.application.eager_load!
      ActiveRecord::Base.descendants.select do |klass|
        klass.included_modules.any? { |mod| mod.in?([ NoFlyList::TaggableRecord ]) }
      end
    end

    def self.find_tag_classes
      Rails.application.eager_load!
      ActiveRecord::Base.descendants.select do |klass|
        klass.included_modules.any? { |mod| mod.in?([ NoFlyList::ApplicationTag, NoFlyList::TagRecord ]) }
      end
    end
  end
end
