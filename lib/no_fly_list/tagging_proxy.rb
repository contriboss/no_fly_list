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

    # Creates a new tagging proxy
    # @param model [ActiveRecord::Base] Model being tagged
    # @param tag_model [Class] Tag model class
    # @param context [Symbol] Tagging context (e.g. :colors)
    # @param transformer [Class] Class for transforming tag strings
    # @param restrict_to_existing [Boolean] Only allow existing tags
    # @param limit [Integer, nil] Maximum number of tags allowed
    def initialize(model, tag_model, context,
                   transformer: "ApplicationTagTransformer",
                   restrict_to_existing: false,
                   limit: nil)
      @model = model
      @tag_model = tag_model
      @context = context
      @transformer = resolve_transformer(transformer)
      @restrict_to_existing = restrict_to_existing
      @limit = limit
      @pending_changes = nil # Use nil to indicate no changes yet
      @clear_operation = false
    end

    def resolve_transformer(trans)
      const = trans
      const = const.constantize if const.is_a?(String)
      unless const.respond_to?(:parse_tags) && const.respond_to?(:recreate_string)
        warn "NoFlyList: transformer #{trans.inspect} is invalid. Falling back to DefaultTransformer"
        const = NoFlyList::DefaultTransformer
      end
      const
    rescue NameError
      warn "NoFlyList: transformer #{trans.inspect} not found. Falling back to DefaultTransformer"
      NoFlyList::DefaultTransformer
    end

    # Determines if tags have changed from database state
    # @return [Boolean] True if pending changes differ from database
    # @api private
    def changed?
      @clear_operation || (!@pending_changes.nil? && @pending_changes != current_list_from_database)
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

    # Handles numeric coercion
    # @param other [Object] Object to coerce with
    # @return [Array] Two-element array for coercion
    def coerce(other)
      [ other, to_a ]
    end

    def to_ary
      current_list
    end

    # @return [Boolean] true if the proxy is valid
    def save
      return true unless changed?
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
          pending_list.each do |tag_name|
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
        model.update_column("#{@context}_count", pending_list.size) if setup[:counter_cache]

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
      # Always return the database count for count operations
      @model.send(@context.to_s).count
    end

    # @return [Integer]
    def size
      # For size, return the database count if we've had a validation error
      if !valid?
        count
        # Otherwise show pending changes
      elsif @clear_operation
        0
      elsif !@pending_changes.nil?
        @pending_changes.size
      else
        count
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

    # Returns tags that will be added (not in database but in pending changes)
    # @return [Array<String>] Tags to be added
    def additions
      return [] if @clear_operation
      return [] if @pending_changes.nil?

      @pending_changes - current_list_from_database
    end

    # Returns tags that will be removed (in database but not in pending changes)
    # @return [Array<String>] Tags to be removed
    def removals
      if @clear_operation
        current_list_from_database
      elsif @pending_changes.nil?
        []
      else
        current_list_from_database - @pending_changes
      end
    end

    # @return [String]
    def inspect
      if @clear_operation
        db_tags = current_list_from_database
        "#<#{self.class.name} tags=[] changes=[CLEARING ALL (#{db_tags.size}): #{db_tags.inspect}] transformer_with=#{transformer_name}>"
      elsif !@pending_changes.nil?
        add_list = additions
        remove_list = removals
        changes = []
        changes << "+#{add_list.inspect}" if add_list.any?
        changes << "-#{remove_list.inspect}" if remove_list.any?
        changes_str = changes.join(", ")

        "#<#{self.class.name} tags=#{current_list.inspect} changes=[#{changes_str}] transformer_with=#{transformer_name}>"
      else
        "#<#{self.class.name} tags=#{current_list.inspect} transformer_with=#{transformer_name}>"
      end
    end

    # Adds one or more tags to the current tag list
    # @param *tags [Array<String, Array<String>>] Tags to add:
    #   - Single string with comma-separated values ("tag1, tag2")
    #   - Single array of strings (["tag1", "tag2"])
    #   - Multiple string arguments ("tag1", "tag2")
    # @return [TaggingProxy] Returns self for method chaining
    def add(*tags)
      return self if limit_reached?

      @clear_operation = false
      new_tags = if tags.size == 1 && tags.first.is_a?(String)
                   transformer.parse_tags(tags.first)
      else
                   tags.flatten.map { |tag| transformer.parse_tags(tag) }.flatten
      end
      return self if new_tags.empty?

      # Initialize @pending_changes with database values if not yet initialized
      @pending_changes = current_list_from_database if @pending_changes.nil?

      @pending_changes = @pending_changes + new_tags
      @pending_changes.uniq!
      mark_record_dirty
      self
    end

    def add!(*tags)
      add(*tags)
      save
    end

    # Removes one or more tags from the current tag list
    # @param *tags [Array<String, Array<String>>] Tags to remove:
    #   - Single string with comma-separated values ("tag1, tag2")
    #   - Single array of strings (["tag1", "tag2"])
    #   - Multiple string arguments ("tag1", "tag2")
    # @return [TaggingProxy] Returns self for method chaining
    # @raise [ActiveRecord::RecordInvalid] If validation fails
    def remove(*tags)
      @clear_operation = false

      # Initialize @pending_changes with database values if not yet initialized
      @pending_changes = current_list_from_database if @pending_changes.nil?

      old_list = @pending_changes.dup

      tags_to_remove = if tags.size == 1 && tags.first.is_a?(String)
                         transformer.parse_tags(tags.first)
      else
                         tags.flatten.map { |tag| tag.to_s.strip }
      end

      @pending_changes = @pending_changes - tags_to_remove
      mark_record_dirty if @pending_changes != old_list
      self
    end

    def remove!(tag)
      remove(tag)
      save
    end

    # Clears all tags
    # @return [TaggingProxy] Returns self for method chaining
    # @example Clear all tags
    #   tags.clear #=> []
    def clear
      @clear_operation = true
      @pending_changes = []
      mark_record_dirty if current_list_from_database.any?
      model.write_attribute("#{@context}_count", 0) if setup[:counter_cache]
      self
    end

    # Forces clearing all tags by destroying records
    # @return [TaggingProxy] Returns self for method chaining
    # @example Force clear tags
    #   tags.clear! #=> []
    # @raise [ActiveRecord::RecordNotDestroyed] If destroy fails
    def clear!
      @model.send(@context.to_s).destroy_all
      @pending_changes = []
      @clear_operation = false
      @model.update_column("#{@context}_count", 0) if setup[:counter_cache]
      self
    end

    # Checks if a tag exists in the list
    # @param tag [String] Tag to check for
    # @return [Boolean] True if tag exists
    def include?(tag)
      current_list.include?(tag.to_s.strip)
    end

    # Checks if tag list is empty
    # @return [Boolean] True if no tags exist
    def empty?
      current_list.empty?
    end

    # Required by ActiveModel::Validations
    # @return [Boolean] Always returns false since proxy isn't persisted
    # @api private
    # @see https://api.rubyonrails.org/classes/ActiveModel/Validations.html
    def persisted?
      false
    end

    private

    def current_list_from_database
      if setup[:polymorphic]
        tagging_klass = setup[:tagging_class_name].constantize
        tagging_table = tagging_klass.arel_table

        @model.send(@context.to_s)
              .where(tagging_table[:taggable_type].eq(@model.class.name))
              .where(tagging_table[:taggable_id].eq(@model.id))
              .pluck(:name)
      else
        @model.send(@context.to_s).pluck(:name)
      end
    end

    def set_list(_context, value)
      @clear_operation = false
      @pending_changes = transformer.parse_tags(value).uniq.reject(&:blank?)
      mark_record_dirty
      valid? # Just check validity without raising
      self
    end

    def get_list(_context)
      current_list
    end

    def refresh_from_database
      @pending_changes = nil
      @clear_operation = false
    end

    def validate_limit
      return unless @limit
      return if pending_list.size <= @limit

      errors.add(:base, "Cannot have more than #{@limit} tags (attempting to save #{pending_list.size})")
    end

    def validate_existing_tags
      return unless @restrict_to_existing
      return if pending_list.empty?

      # Transform tags to lowercase for comparison
      normalized_changes = pending_list.map(&:downcase)
      existing_tags = @tag_model.where("LOWER(name) IN (?)", normalized_changes).pluck(:name)
      missing_tags = pending_list - existing_tags

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

    # Helper method to get the list of tags that should be saved
    def pending_list
      if @clear_operation
        []
      elsif !@pending_changes.nil?
        @pending_changes
      else
        current_list_from_database
      end
    end

    def current_list
      # If validation failed, always return what's in the database
      if errors.any?
        current_list_from_database
      elsif @clear_operation
        []
      elsif !@pending_changes.nil?
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
