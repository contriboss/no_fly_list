# frozen_string_literal: true

namespace :no_fly_list do
  desc 'List all taggable records'
  task taggable_records: :environment do
    Rails.application.eager_load!
    taggable_classes = ActiveRecord::Base.descendants.select do |klass|
      klass.included_modules.any? { |mod| mod.in?([NoFlyList::TaggableRecord]) }
    end

    puts "Found #{taggable_classes.size} taggable classes:\n\n"

    taggable_classes.each do |klass|
      puts "Class: #{klass.name}"
    end
  end

  desc 'List all tag records'
  task tag_records: :environment do
    Rails.application.eager_load!
    tag_classes = ActiveRecord::Base.descendants.select do |klass|
      klass.included_modules.any? { |mod| mod.in?([NoFlyList::ApplicationTag, NoFlyList::TagRecord]) }
    end

    puts "Found #{tag_classes.size} tag classes:\n\n"

    tag_classes.each do |klass|
      puts "Class: #{klass.name}"
    end
  end

  desc 'Check taggable records and their associated tables'
  task check_taggable_records: :environment do
    Rails.application.eager_load!
    taggable_classes = ActiveRecord::Base.descendants.select do |klass|
      klass.included_modules.any? { |mod| mod.in?([NoFlyList::TaggableRecord]) }
    end

    puts "Checking #{taggable_classes.size} taggable classes:\n\n"

    taggable_classes.each do |klass|
      puts "Checking Class: #{klass.name}"

      # ANSI color codes
      green = "\e[32m"
      red = "\e[31m"
      reset = "\e[0m"

      # Check main table exists
      begin
        klass.table_exists?
        puts "  #{green}✓#{reset} Main table exists: #{klass.table_name}"
      rescue StandardError => e
        puts "  #{red}✗#{reset} Error checking main table: #{e.message}"
      end

      # Dynamically find tag and tagging class names
      tag_class_name = "#{klass.name}Tag"
      tagging_class_name = "#{klass.name}::Tagging"

      begin
        tag_class = Object.const_get(tag_class_name)

        # Check tags table exists
        if tag_class.table_exists?
          puts "  #{green}✓#{reset} Tags table exists: #{tag_class.table_name}"
        else
          puts "  #{red}✗#{reset} Tags table missing: #{tag_class.table_name}"
        end
      rescue NameError
        puts "  #{red}✗#{reset} Tag class not found: #{tag_class_name}"
      rescue StandardError => e
        puts "  #{red}✗#{reset} Error checking tag class: #{e.message}"
      end

      begin
        tagging_class = Object.const_get(tagging_class_name)

        # Check taggings table exists
        if tagging_class.table_exists?
          puts "  #{green}✓#{reset} Taggings table exists: #{tagging_class.table_name}"
        else
          puts "  #{red}✗#{reset} Taggings table missing: #{tagging_class.table_name}"
        end
      rescue NameError
        puts "  #{red}✗#{reset} Tagging class not found: #{tagging_class_name}"
      rescue StandardError => e
        puts "  #{red}✗#{reset} Error checking tagging class: #{e.message}"
      end

      puts "\n"
    end
  end
end
