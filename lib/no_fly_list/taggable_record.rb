# frozen_string_literal: true

module NoFlyList
  module TaggableRecord
    extend ActiveSupport::Concern

    # @!attribute _no_fly_list
    #   @return [Config] Configuration for this taggable record
    #
    # @!method save_tag_proxies
    #   @api private
    #   Saves pending tag changes before saving the record
    included do
      class_attribute :_no_fly_list, instance_writer: false
      self._no_fly_list = Config.new self

      before_save :save_tag_proxies
      before_validation :validate_tag_proxies
    end

    # Determines if record needs saving due to tag changes
    # @return [Boolean] True if tags have pending changes
    # @api private
    def changed_for_autosave?
      super || tag_proxies_changed?
    end

    private

    def validate_tag_proxies
      return true if @validating_proxies

      @validating_proxies = true
      begin
        instance_variables.each do |var|
          next unless var.to_s.match?(/_list_proxy$/)

          proxy = instance_variable_get(var)
          next if proxy.nil? || proxy.valid?

          proxy.errors.each do |error|
            errors.add(:base, error.message)
          end
          return false
        end
        true
      ensure
        @validating_proxies = false
      end
    end

    def save_tag_proxies
      return true if @saving_proxies

      @saving_proxies = true
      begin
        instance_variables.each do |var|
          next unless var.to_s.match?(/_list_proxy$/)

          proxy = instance_variable_get(var)
          next if proxy.nil?
          unless proxy.save
            proxy.errors.each do |error|
              errors.add(:base, error.message)
            end
            throw :abort
          end
        end
        true
      ensure
        @saving_proxies = false
      end
    end

    def no_fly_list_config
      self.class._no_fly_list
    end

    def tag_contexts
      no_fly_list_config.tag_contexts
    end

    def options_for_context(context)
      tag_contexts[context.to_sym]
    end

    def tag_proxies_changed?
      return false if @saving_proxies || @validating_proxies

      instance_variables.any? do |var|
        next unless var.to_s.match?(/_list_proxy$/)

        proxy = instance_variable_get(var)
        next if proxy.nil?

        proxy.changed?
      end
    end

    # Class methods added to taggable models
    # @!method has_tags(*contexts, **options)
    #   Configures tagging contexts for the model
    #   @param contexts [Array<Symbol>] Tag context names
    #   @param options [Hash] Options for configuring tagging
    class_methods do
      def has_tags(*contexts, **options)
        contexts.each do |context|
          _no_fly_list.add_context(context, options)
        end

        Configuration.setup_tagging(self, contexts, options)
      end
    end
  end
end
