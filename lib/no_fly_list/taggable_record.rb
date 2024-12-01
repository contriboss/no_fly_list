# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    extend ActiveSupport::Concern

    included do
      before_save :save_tag_proxies
    end

    private

    def save_tag_proxies
      instance_variables.each do |var|
        next unless var.to_s.match?(/_list_proxy$/)

        proxy = instance_variable_get(var)
        return false unless proxy.save
      end
    end

    class_methods do
      def has_tags(*contexts, **options)
        Configuration.setup_tagging(self, contexts, options)
      end
    end
  end
end
