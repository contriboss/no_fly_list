# frozen_string_literal: true

require 'active_record/railtie'
require 'rails'

module NoFlyList
  class Railtie < Rails::Railtie # :nodoc:
    config.no_fly_list = ActiveSupport::OrderedOptions.new
    config.no_fly_list.tag_class_name = 'ApplicationTag'
    config.no_fly_list.tag_table_name = 'application_tags'
    config.no_fly_list.tagging_class_name = 'ApplicationTagging'
    config.no_fly_list.tagging_table_name = 'application_taggings'

    rake_tasks do
      load 'no_fly_list/railties/tasks.rake'
    end
  end
end
