namespace :no_fly_list do
  desc "List all models using NoFlyList::TaggableRecord with details about their tagging configurations"
  task taggable_records: :environment do
    classes = NoFlyList::TaskHelpers.find_taggable_classes
    puts "Found #{classes.size} taggable classes:\n\n"

    classes.each do |klass|
      color = NoFlyList::TaskHelpers.adapter_color(klass)
      puts "#{color}#{klass.name}#{NoFlyList::TaskHelpers::COLORS[:reset]}"
      puts "  Tag Contexts: #{klass._no_fly_list&.tag_contexts&.keys&.join(', ')}"
      puts "  Tables: #{klass.table_name}"
      puts
    end
  end

  desc "List all tag classes (both global and model-specific) with their inheritance chain"
  task tag_records: :environment do
    classes = NoFlyList::TaskHelpers.find_tag_classes
    puts "Found #{classes.size} tag classes:\n\n"

    classes.each do |klass|
      color = NoFlyList::TaskHelpers.adapter_color(klass)
      type = klass.included_modules.include?(NoFlyList::ApplicationTag) ? 'Global' : 'Model-specific'

      puts "#{color}#{klass.name}#{NoFlyList::TaskHelpers::COLORS[:reset]}"
      puts "  Type: #{type}"
      puts "  Table: #{klass.table_name}"
      puts
    end
  end

  desc "Validate database schema for all taggable models"
  task check_taggable_records: :environment do
    classes = NoFlyList::TaskHelpers.find_taggable_classes
    puts "Checking #{classes.size} taggable classes:\n\n"

    classes.each do |klass|
      color = NoFlyList::TaskHelpers.adapter_color(klass)
      puts "Checking Class: #{color}#{klass.name}#{NoFlyList::TaskHelpers::COLORS[:reset]}"

      status, message = NoFlyList::TaskHelpers.check_table(klass)
      puts "  #{message}"

      [
        ["#{klass.name}Tag", "Tags", :tag],
        ["#{klass.name}::Tagging", "Taggings", :tagging]
      ].each do |class_name, type, column_type|
        if (check_class = NoFlyList::TaskHelpers.check_class(class_name))
          status, message = NoFlyList::TaskHelpers.check_table(check_class)
          puts "  #{message}"
          if status
            puts "  #{NoFlyList::TaskHelpers.verify_columns(check_class, column_type)}"
            puts "  #{NoFlyList::TaskHelpers.format_columns(check_class)}"
          end
        else
          puts "  #{NoFlyList::TaskHelpers::colorize('✗', :red)} #{type} class not found: #{class_name}"
        end
      end

      klass._no_fly_list.tag_contexts.each do |context, config|
        puts "\n  Context: #{context}"
        bullet = NoFlyList::TaskHelpers::colorize('•', :green)
        puts "  #{bullet} Tag class: #{config[:tag_class_name]}"
        puts "  #{bullet} Tagging class: #{config[:tagging_class_name]}"
        puts "  #{bullet} Polymorphic: #{config[:polymorphic]}"
        if config[:polymorphic]
          puts "  #{bullet} Required tagging columns: context, tag_id, taggable_id, taggable_type"
        end
      end
      puts "\n"
    end
  end
end
