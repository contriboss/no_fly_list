# frozen_string_literal: true

module NoFlyList
  class TaggingProxy
    include Enumerable
    include ActiveModel::Conversion
    include ActiveModel::Validations
    extend ActiveModel::Naming

    delegate :blank?, :present?, :each, :==, to: :current_list
    attr_reader :model, :tag_model, :context, :transformer

    validate :validate_limit
    validate :validate_existing_tags

    def initialize(model, tag_model, context,
                   transformer: ApplicationTagTransformer,
                   restrict_to_existing: false,
                   limit: nil)
      @model = model
      @tag_model = tag_model
      @context = context
      @transformer = transformer.is_a?(String) ? transformer.constantize : transformer
      @restrict_to_existing = restrict_to_existing
      @limit = limit
      @pending_changes = []
    end

    def changed?
      @pending_changes.present? && @pending_changes != current_list_from_database
    end

    def method_missing(method_name, *args)
      if current_list.respond_to?(method_name)
        current_list.send(method_name, *args)
      else
        case method_name.to_s
        when /\A(.+)_list=\z/
          set_list(::Regexp.last_match(1), args.first)
        when /\A(.+)_list\z/
          get_list(::Regexp.last_match(1))
        else
          super
        end
      end
    end

    def respond_to_missing?(method_name, _include_private = false)
      current_list.respond_to?(method_name) ||
        method_name.to_s =~ /\A(.+)_list(=)?\z/
    end

    def coerce(other)
      [ other, to_a ]
    end

    def to_ary
      current_list
    end

    # @return [Boolean] true if the proxy is valid
    def save
      return true unless @pending_changes.any?
      return false unless valid?

      # Prevent recursive validation
      @saving = true
      begin
        model.class.transaction do
          # Always save parent first if needed
          if model.new_record? && !model.save
            errors.add(:base, "Failed to save parent record")
            raise ActiveRecord::Rollback
          end

          # Clear existing tags
          old_count = model.send(context_taggings).count
          model.send(context_taggings).delete_all

          # Update counter
          model.update_column("#{@context}_count", 0) if setup[:counter_cache]
          # Create new tags
          @pending_changes.each do |tag_name|
            tag = find_or_create_tag(tag_name)
            next unless tag

            attributes = {
              tag: tag,
              context: @context.to_s.singularize
            }

            if setup[:polymorphic]
              attributes[:taggable_type] = model.class.name
              attributes[:taggable_id] = model.id
            end

            # Use create! to ensure we catch any errors
            model.send(context_taggings).create!(attributes)
          end
        end
        # Update counter to match the actual count
        model.update_column("#{@context}_count", @pending_changes.size) if setup[:counter_cache]

        refresh_from_database
        true
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
        errors.add(:base, e.message)
        false
      ensure
        @saving = false
      end
    end

    # @raise [ActiveModel::ValidationError] if the proxy is not valid
    # @return [Boolean] true if the proxy is valid and the changes were saved
    def save!
      valid? || raise(ActiveModel::ValidationError, self)
      save
    end

    # @return [Integer]
    def count
      @model.send(@context.to_s).count
    end

    # @return [Integer]
    def size
      if @pending_changes.any?
        @pending_changes.size
      else
        @model.send(@context.to_s).size
      end
    end

    # @return [Array<String>]
    def to_a
      current_list
    end

    # @return [String]
    def to_s
      transformer.recreate_string(current_list)
    end

    # @return [String] The name of the parser used to transform tags
    def transformer_name
      @transformer_name ||= transformer.name
    end

    # @return [String]
    def inspect
      "#<#{self.class.name} tags=#{current_list.inspect} transformer_with=#{transformer_name} >"
    end

    # Adds one or more tags to the current tag list
    # @param *tags [Array<String, #to_s>] Tags to add, can be:
    #   - A comma-separated string ("tag1, tag2")
    #   - An array of strings (["tag1", "tag2"])
    #   - Multiple string arguments ("tag1", "tag2")
    # @return [self] Returns self for method chaining
    def add(*tags)
      return self if limit_reached?

      new_tags = if tags.size == 1 && tags.first.is_a?(String)
                   transformer.parse_tags(tags.first)
      else
                   tags.flatten.map { |tag| transformer.parse_tags(tag) }.flatten
      end
      return self if new_tags.empty?

      @pending_changes = current_list + new_tags
      @pending_changes.uniq!
      self
    end

    def add!(*tags)
      add(*tags)
      save
    end

    # Removes one or more tags from the current tag list
    # @param *tags [Array<String, #to_s>] Tags to remove, can be:
    #   - A comma-separated string ("tag1, tag2")
    #   - An array of strings (["tag1", "tag2"])
    #   - Multiple string arguments ("tag1", "tag2")
    # @return [self] Returns self for method chaining
    def remove(*tags)
      old_list = current_list.dup
      tags_to_remove = if tags.size == 1 && tags.first.is_a?(String)
                         transformer.parse_tags(tags.first)
      else
                         tags.flatten.map { |tag| tag.to_s.strip }
      end
      @pending_changes = current_list - tags_to_remove
      mark_record_dirty if @pending_changes != old_list
      self
    end

    def remove!(tag)
      remove(tag)
      save
    end

    def clear
      old_list = current_list.dup
      @pending_changes = []
      mark_record_dirty if @pending_changes != old_list
      model.write_attribute("#{@context}_count", 0) if setup[:counter_cache]
      self
    end

    def clear!
      @model.send(@context.to_s).destroy_all
      @pending_changes = []
      @model.update_column("#{@context}_count", 0) if setup[:counter_cache]
      self
    end

    def include?(tag)
      current_list.include?(tag.to_s.strip)
    end

    def empty?
      current_list.empty?
    end

    def persisted?
      false
    end

    private

    def current_list_from_database
      if setup[:polymorphic]
        tagging_table = setup[:tagging_class_name].tableize
        @model.send(@context.to_s)
              .joins("INNER JOIN #{tagging_table} ON #{tagging_table}.tag_id = tags.id")
              .where("#{tagging_table}.taggable_type = ? AND #{tagging_table}.taggable_id = ?",
                     @model.class.name, @model.id)
              .pluck(:name)
      else
        @model.send(@context.to_s).pluck(:name)
      end
    end

    def set_list(_context, value)
      @pending_changes = transformer.parse_tags(value)
      valid? # Just check validity without raising
      self
    end

    def get_list(_context)
      current_list
    end

    def refresh_from_database
      @pending_changes = []
    end

    def validate_limit
      return unless @limit
      return if @pending_changes.size <= @limit

      errors.add(:base, "Cannot have more than #{@limit} tags (attempting to save #{@pending_changes.size})")
    end

    def validate_existing_tags
      return unless @restrict_to_existing
      return if @pending_changes.empty?

      # Transform tags to lowercase for comparison
      normalized_changes = @pending_changes.map(&:downcase)
      existing_tags = @tag_model.where("LOWER(name) IN (?)", normalized_changes).pluck(:name)
      missing_tags = @pending_changes - existing_tags

      return unless missing_tags.any?

      errors.add(:base, "The following tags do not exist: #{missing_tags.join(', ')}")
    end

    def context_taggings
      @context_taggings ||= "#{@context.to_s.singularize}_taggings"
    end

    def setup
      @setup ||= begin
        context = @context.to_sym
        @model.class._no_fly_list.tag_contexts[context]
      end
    end

    def find_or_create_tag(tag_name)
      if @restrict_to_existing
        @tag_model.find_by(name: tag_name)
      else
        @tag_model.find_or_create_by(name: tag_name)
      end
    end

    def save_changes
      # Clear existing tags
      model.send(context_taggings).delete_all

      # Create new tags
      @pending_changes.each do |tag_name|
        tag = find_or_create_tag(tag_name)
        next unless tag

        attributes = {
          tag: tag,
          context: @context.to_s.singularize
        }

        # Add polymorphic attributes for polymorphic tags
        if setup[:polymorphic]
          attributes[:taggable_type] = model.class.name
          attributes[:taggable_id] = model.id
        end

        # Use create! to ensure we catch any errors
        model.send(context_taggings).create!(attributes)
      end

      refresh_from_database
      true
    end

    def current_list
      if @pending_changes.any?
        @pending_changes
      else
        current_list_from_database
      end
    end

    def limit_reached?
      @limit && current_list.size >= @limit
    end

    def mark_record_dirty
      return unless model.respond_to?(:changed_attributes)

      # We use a virtual attribute name based on the context
      # This ensures the record is marked as changed when tags are modified
      model.send(:attribute_will_change!, "#{context}_list")
    end
  end
end
