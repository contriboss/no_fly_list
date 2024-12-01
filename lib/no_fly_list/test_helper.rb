# frozen_string_literal: true

module NoFlyList
  # = NoFlyList Test Helper
  #
  # Include <tt>NoFlyList::TestHelper</tt> in your test case to get access to the assertion methods.
  module TestHelper
    def assert_taggable_record(klass, *contexts)
      assert klass.respond_to?(:has_tags), "#{klass} does not respond to has_tags"
      contexts.each do |context|
        assert klass.new.respond_to?(:"#{context}_list"), "#{klass} does not respond to #{context}_list"
      end
    end
  end
end
