# frozen_string_literal: true

require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  include NoFlyList::TestHelper
  fixtures :companies
  # Test associations for industries
  test "has many industry_taggings" do
    assert have_many(:industry_taggings).matches?(Company.new)
  end

  test "has many industries through industry_taggings" do
    assert have_many(:industries).through(:industry_taggings).matches?(Company.new)
  end

  test "assert_taggable_record" do
    assert_taggable_record(Company, :industries)
  end

  test "use another transformer" do
    company = companies(:ftx)
    assert company.industries.empty?
    company.industries_list = "Crypto; Blockchain; NFT; Mass Scam"
    assert_equal 4, company.industries_list.size
    assert company.save
    assert_equal 4, company.industries_list.count
  end
end
