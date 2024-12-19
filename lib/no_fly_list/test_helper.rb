# frozen_string_literal: true

module NoFlyList
  module TestHelper
    # Asserts that a model class is properly set up for tagging in the given context
    def assert_taggable_record(klass, *contexts)
      contexts.each do |context|
        assert klass._no_fly_list.tag_contexts.key?(context),
               "#{klass} should have #{context} in its tag contexts"

        assert_respond_to klass.new, "#{context}_list",
                          "#{klass} should respond to #{context}_list"
      end
    end

    # Asserts that a model class has proper tagging setup for a specific context
    def assert_tagging_context(klass, context, polymorphic: false)
      singular_name = context.to_s.singularize

      # Check the context is registered
      assert klass._no_fly_list.tag_contexts.key?(context),
             "#{context} is not registered as a tag context for #{klass}"

      # Check configuration
      context_config = klass._no_fly_list.tag_contexts[context]
      assert_equal polymorphic, context_config[:polymorphic],
                   "#{context} should #{polymorphic ? '' : 'not '}be configured as polymorphic"

      # Check tagging associations
      assert_respond_to klass.new, "#{singular_name}_taggings",
                        "Missing taggings association for #{context}"
      assert_respond_to klass.new, context,
                        "Missing tags association for #{context}"

      # Check if correct classes exist
      if polymorphic
        assert_polymorphic_tag_classes_exist(klass, context)
      else
        assert_local_tag_classes_exist(klass, context)
      end
    end

    private

    def assert_polymorphic_tag_classes_exist(tags_klass, tagging_klass)
      # Verify they include the correct modules
      assert tags_klass.include?(NoFlyList::ApplicationTag),
             "Polymorphic Tag should include NoFlyList::ApplicationTag"
      assert tagging_klass.include?(NoFlyList::ApplicationTagging),
             "Polymorphic Tagging should include NoFlyList::ApplicationTagging"
    end

    def assert_local_tag_classes_exist(klass, context)
      context.to_s.singularize

      # Check tag class exists
      tag_class = "#{klass.name}Tag"
      assert tag_class.safe_constantize,
             "Tag class #{tag_class} should exist"

      # Check tagging class exists
      tagging_class = "#{klass.name}::Tagging"
      assert tagging_class.safe_constantize,
             "Tagging class #{tagging_class} should exist"

      # Verify they include the correct modules
      assert tag_class.constantize.include?(NoFlyList::TagRecord),
             "#{tag_class} should include NoFlyList::TagRecord"
      assert tagging_class.constantize.include?(NoFlyList::TaggingRecord),
             "#{tagging_class} should include NoFlyList::TaggingRecord"
    end

    # Asserts that a specific record has a tag in a given context
    def assert_has_tag(record, tag_name, context)
      tag_list = record.send("#{context}_list")
      assert_includes tag_list.to_a, tag_name,
                      "Expected #{record.class.name} ##{record.id} to have tag '#{tag_name}' in context '#{context}'"
    end

    # Asserts that a specific record does not have a tag in a given context
    def assert_has_no_tag(record, tag_name, context)
      tag_list = record.send("#{context}_list")
      refute_includes tag_list.to_a, tag_name,
                      "Expected #{record.class.name} ##{record.id} to not have tag '#{tag_name}' in context '#{context}'"
    end

    # Asserts that a specific record has exactly the given tags in a context
    def assert_has_exactly_tags(record, tags, context)
      actual_tags = record.send("#{context}_list").to_a.sort
      expected_tags = Array(tags).sort
      assert_equal expected_tags, actual_tags,
                   "Expected #{record.class.name} ##{record.id} to have exactly #{expected_tags.inspect} in context '#{context}', but got #{actual_tags.inspect}"
    end
  end
end
