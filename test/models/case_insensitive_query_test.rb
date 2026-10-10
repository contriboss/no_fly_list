# frozen_string_literal: true

require "test_helper"

class CaseInsensitiveQueryTest < ActiveSupport::TestCase
  class UnscopedTests < ActiveSupport::TestCase
    setup do
      @exchange = Company.create!(name: "Exchange")
      @wallet = Company.create!(name: "Wallet")
      @bakery = Company.create!(name: "Bakery")

      @exchange.keywords_list = [ "Crypto", "Exchange" ]
      @exchange.save!
      @wallet.keywords_list = "crypto"
      @wallet.save!
      @bakery.keywords_list = "Bread"
      @bakery.save!
    end

    test "with_any ignores case" do
      assert_equal [ @exchange, @wallet ].to_set, Company.with_any_keywords("CRYPTO").to_set
    end

    test "with_all ignores case" do
      assert_equal [ @exchange ], Company.with_all_keywords("crypto", "EXCHANGE").to_a
      assert_equal [ @exchange, @wallet ].to_set, Company.with_all_keywords("crypto", "Crypto").to_set
    end

    test "with_exact ignores case" do
      assert_equal [ @wallet ], Company.with_exact_keywords("CRYPTO").to_a
      assert_equal [ @exchange ], Company.with_exact_keywords("exchange", "crypto").to_a
    end

    test "without_any ignores case" do
      result = Company.without_any_keywords("EXCHANGE", "bread")

      assert_includes result, @wallet
      assert_not_includes result, @exchange
      assert_not_includes result, @bakery
    end

    test "compares lowered names in SQL" do
      assert_match(/LOWER\(.*name.*\) IN \(LOWER\('CRYPTO'\)\)/, Company.with_any_keywords("CRYPTO").to_sql)
      assert_match(/LOWER\(company_tags\.name\)/, Company.with_exact_keywords("CRYPTO").to_sql)
    end
  end

  class ScopedTests < ActiveSupport::TestCase
    # Carol is tagged at Acme, then moves to Zenith, so her tags stay in
    # Acme's scope and must not match.
    setup do
      @acme = Airline.create!(name: "Acme Air")
      @zenith = Airline.create!(name: "Zenith")
      @alice = CrewMember.create!(airline: @acme, name: "Alice")
      @bob = CrewMember.create!(airline: @acme, name: "Bob")
      @zoe = CrewMember.create!(airline: @zenith, name: "Zoe")
      @carol = CrewMember.create!(airline: @acme, name: "Carol")

      @alice.roles_list = [ "Purser", "Captain" ]
      @alice.certifications_list = "A320"
      @zoe.roles_list = "purser"
      @zoe.certifications_list = "a320"
      @carol.roles_list = "PURSER"
      @carol.certifications_list = "a320"
      [ @alice, @zoe, @carol ].each(&:save!)
      @carol.update_column(:airline_id, @zenith.id)
    end

    test "with_any ignores case within the scope" do
      assert_equal [ @alice, @zoe ].to_set, CrewMember.with_any_roles("PURSER").to_set
    end

    test "with_all ignores case within the scope" do
      assert_equal [ @alice ], CrewMember.with_all_roles("purser", "CAPTAIN").to_a
      assert_equal [ @alice, @zoe ].to_set, CrewMember.with_all_roles("purser", "PURSER").to_set
    end

    test "with_exact ignores case within the scope" do
      assert_equal [ @alice ], CrewMember.with_exact_roles("CAPTAIN", "purser").to_a
      assert_equal [ @zoe ], CrewMember.with_exact_roles("Purser").to_a
    end

    test "without_any ignores case within the scope" do
      assert_equal [ @bob, @zoe, @carol ].to_set, CrewMember.without_any_roles("CAPTAIN").to_set
      assert_equal [ @bob, @carol ].to_set, CrewMember.without_any_roles("PuRsEr").to_set
    end

    test "polymorphic tags ignore case within the scope" do
      assert_equal [ @alice, @zoe ].to_set, CrewMember.with_any_certifications("A320").to_set
      assert_equal [ @alice, @zoe ].to_set, CrewMember.with_all_certifications("a320").to_set
      assert_equal [ @alice, @zoe ].to_set, CrewMember.with_exact_certifications("A320").to_set
      assert_equal [ @bob, @carol ].to_set, CrewMember.without_any_certifications("a320").to_set
    end
  end

  class CaseSensitiveTests < ActiveSupport::TestCase
    setup do
      skip "MySQL's default collation compares names case insensitively" if model_adapter(CrewMember) == :mysql2

      @acme = Airline.create!(name: "Acme Air")
      @alice = CrewMember.create!(airline: @acme, name: "Alice")
      @alice.skills_list = "First Aid"
      @alice.save!
    end

    test "scoped queries match names exactly by default" do
      assert_empty CrewMember.with_any_skills("first aid")
      assert_empty CrewMember.with_all_skills("first aid")
      assert_empty CrewMember.with_exact_skills("first aid")
      assert_includes CrewMember.without_any_skills("first aid"), @alice
      assert_equal [ @alice ], CrewMember.with_any_skills("First Aid").to_a
    end

    test "unscoped queries match names exactly by default" do
      passenger = Passenger.create!(first_name: "Ada")
      passenger.special_needs_list = "Wheelchair"
      passenger.save!

      assert_empty Passenger.with_any_special_needs("wheelchair")
      assert_empty Passenger.with_all_special_needs("wheelchair")
      assert_empty Passenger.with_exact_special_needs("wheelchair")
      assert_includes Passenger.without_any_special_needs("wheelchair"), passenger
      assert_equal [ passenger ], Passenger.with_any_special_needs("Wheelchair").to_a
    end
  end
end
