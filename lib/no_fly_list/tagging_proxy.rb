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
      [other, to_a]
    end

    def to_ary
      current_list
    end

    # @return [Boolean] true if the proxy is valid
    def save
      return true unless @pending_changes.any?

      if valid?
        @model.transaction do
          @model.send(@context.to_s).destroy_all
          @pending_changes.each do |tag_name|
            tag = find_or_create_tag(tag_name)
            @model.send(@context.to_s) << tag if tag
          end
        end
        refresh_from_database
        true
      else
        false
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

    def add(tag)
      return self if limit_reached?

      new_tags = transformer.parse_tags(tag)
      return self if new_tags.empty?

      @pending_changes = current_list + new_tags
      @pending_changes.uniq!
      self
    end

    def add!(tag)
      add(tag)
      save
    end

    def remove(tag)
      @pending_changes = current_list - [tag.to_s.strip]
      self
    end

    def remove!(tag)
      remove(tag)
      save
    end

    def clear
      @pending_changes = []
      self
    end

    def clear!
      @model.send(@context.to_s).destroy_all
      @pending_changes = []
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

    def set_list(_context, value)
      @pending_changes = transformer.parse_tags(value)
      valid? # Just check validity without raising
      self
    end

    def get_list(_context)
      current_list
    end

    def current_list
      if @pending_changes.any?
        @pending_changes
      else
        @model.send(@context.to_s).pluck(:name)
      end
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

      existing_tags = @tag_model.where(name: @pending_changes).pluck(:name)
      missing_tags = @pending_changes - existing_tags

      return unless missing_tags.any?

      errors.add(:base, "The following tags do not exist: #{missing_tags.join(', ')}")
    end

    def find_or_create_tag(tag_name)
      if @restrict_to_existing
        @tag_model.find_by(name: tag_name)
      else
        @tag_model.find_or_create_by(name: tag_name)
      end
    end

    def limit_reached?
      @limit && current_list.size >= @limit
    end
  end
end
