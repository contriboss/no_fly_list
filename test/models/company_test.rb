# frozen_string_literal: true

require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  include NoFlyList::TestHelper
  fixtures :companies
  # Test associations for industries
  should have_many(:industry_taggings)
  should have_many(:industries).through(:industry_taggings)

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
