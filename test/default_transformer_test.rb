# frozen_string_literal: true

require "test_helper"

class DefaultTransformerTest < ActiveSupport::TestCase
  class TempCar < SecondaryRecord
    self.table_name = "cars"
    include NoFlyList::TaggableRecord

    has_tags :oops_tags, transformer: "MissingTransformer"
  end

  test "falls back to DefaultTransformer when constant missing" do
    proxy = TempCar.new.oops_tags_list
    assert_equal NoFlyList::DefaultTransformer, proxy.transformer
  end
end
