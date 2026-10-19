# frozen_string_literal: true

require "test_helper"

class CrewMemberTest < ActiveSupport::TestCase
  include NoFlyList::TestHelper

  setup do
    @acme = Airline.create!(name: "Acme Air")
    @zenith = Airline.create!(name: "Zenith")
    @alice = CrewMember.create!(airline: @acme, name: "Alice")
    @bob = CrewMember.create!(airline: @acme, name: "Bob")
    @zoe = CrewMember.create!(airline: @zenith, name: "Zoe")
  end

  test "assert_taggable_record" do
    assert_taggable_record(CrewMember, :skills, :roles, :languages, :certifications)
  end

  test "resolves the scope column from the belongs_to association" do
    assert_equal "airline_id", NoFlyList::TaggableRecord::TagSetup.new(CrewMember, :skills, scope: :airline).scope_column
  end

  test "accepts a column name as the scope" do
    assert_equal "airline_id", NoFlyList::TaggableRecord::TagSetup.new(CrewMember, :skills, scope: :airline_id).scope_column
  end

  test "has no scope column without a scope" do
    assert_nil NoFlyList::TaggableRecord::TagSetup.new(CrewMember, :skills).scope_column
  end

  test "rejects a polymorphic association as the scope" do
    klass = Class.new(ApplicationRecord) do
      self.table_name = "crew_members"
      belongs_to :owner, polymorphic: true
    end

    assert_raises(ArgumentError) do
      NoFlyList::TaggableRecord::TagSetup.new(klass, :skills, scope: :owner).scope_column
    end
  end

  test "rejects contexts that share a tag class with different scopes" do
    config = NoFlyList::Config.new(CrewMember)
    config.add_context(:skills, scope: :airline)

    error = assert_raises(ArgumentError) { config.add_context(:ranks) }
    assert_match(/same tag class CrewMemberTag/, error.message)
  end

  test "records in the same scope share a tag" do
    @alice.skills_list = "first aid"
    @alice.save!
    @bob.skills_list = "first aid"
    @bob.save!

    assert_equal 1, CrewMemberTag.where(name: "first aid").count
    assert_equal @alice.skills.first, @bob.skills.first
  end

  test "scopes sharing a name get separate tags" do
    @alice.skills_list = "first aid"
    @alice.save!
    @zoe.skills_list = "first aid"
    @zoe.save!

    tags = CrewMemberTag.where(name: "first aid")
    assert_equal [ @acme.id, @zenith.id ].sort, tags.pluck(:airline_id).sort
    assert_not_equal @alice.skills.first, @zoe.skills.first
  end

  test "renaming a tag only affects its scope" do
    @alice.skills_list = "first aid"
    @alice.save!
    @zoe.skills_list = "first aid"
    @zoe.save!

    CrewMemberTag.find_by!(airline_id: @acme.id, name: "first aid").update!(name: "cpr")

    assert_equal [ "cpr" ], @alice.reload.skills_list.to_a
    assert_equal [ "first aid" ], @zoe.reload.skills_list.to_a
  end

  test "restrict_to_existing only accepts tags from the record's scope" do
    CrewMemberTag.create!(airline_id: @acme.id, name: "French")

    @alice.languages_list = "French"
    assert @alice.save
    assert_equal [ "French" ], @alice.reload.languages_list.to_a

    @zoe.languages_list = "French"
    assert_not @zoe.save
    assert_match(/do not exist: French/, @zoe.errors.full_messages.join)
    assert_empty @zoe.reload.languages_list.to_a
  end

  test "case insensitive tags match within the scope" do
    @alice.roles_list = "Purser"
    @alice.save!
    @bob.roles_list = "purser"
    @bob.save!
    @zoe.roles_list = "purser"
    @zoe.save!

    assert_equal [ "Purser" ], @bob.reload.roles_list.to_a
    assert_equal @alice.roles.first, @bob.roles.first
    assert_equal [ "purser" ], @zoe.reload.roles_list.to_a
    assert_equal 2, CrewMemberTag.where("LOWER(name) = ?", "purser").count
  end

  test "case insensitive names that differ only in case are tagged once" do
    @alice.roles_list = [ "Purser", "PURSER" ]
    @alice.save!

    assert_equal [ "Purser" ], @alice.reload.roles_list.to_a
    assert_equal 1, CrewMemberTag.where(airline_id: @acme.id).count
  end

  test "case sensitive tags keep names that differ only in case apart" do
    skip "MySQL's default collation compares names case insensitively" if model_adapter(CrewMember) == :mysql2

    @alice.skills_list = "First Aid"
    @alice.save!
    @bob.skills_list = "first aid"
    @bob.save!

    assert_not_equal @alice.skills.first, @bob.skills.first
  end

  test "restrict_to_existing matches case insensitively within the scope" do
    CrewMemberTag.create!(airline_id: @acme.id, name: "French")

    @alice.languages_list = "french"
    assert @alice.save
    assert_equal [ "French" ], @alice.reload.languages_list.to_a

    @zoe.languages_list = "french"
    assert_not @zoe.save
  end

  test "contexts on the same tag table share the scope's tags" do
    CrewMemberTag.create!(airline_id: @acme.id, name: "German")
    @alice.skills_list = "German"
    @alice.save!

    @bob.languages_list = "German"
    assert @bob.save
    assert_equal @alice.skills.first, @bob.languages.first
  end

  test "polymorphic tags are unique per scope" do
    @alice.certifications_list = "A320"
    @alice.save!
    @bob.certifications_list = "A320"
    @bob.save!
    @zoe.certifications_list = "A320"
    @zoe.save!

    tags = ApplicationTag.where(name: "A320")
    assert_equal [ @acme.id, @zenith.id ].sort, tags.pluck(:airline_id).sort
    assert_equal @alice.certifications.first, @bob.certifications.first
    assert_equal [ @alice, @bob, @zoe ].to_set, CrewMember.with_any_certifications("A320").to_set
  end

  class ScopedQueryTests < ActiveSupport::TestCase
    # Carol moves from Acme to Zenith after being tagged, so her taggings
    # point at Acme's tags. Scoped queries must ignore those tags.
    setup do
      @acme = Airline.create!(name: "Acme Air")
      @zenith = Airline.create!(name: "Zenith")
      @alice = CrewMember.create!(airline: @acme, name: "Alice")
      @zoe = CrewMember.create!(airline: @zenith, name: "Zoe")
      @carol = CrewMember.create!(airline: @acme, name: "Carol")
      @untagged = CrewMember.create!(airline: @zenith, name: "Uma")

      [ @alice, @zoe, @carol ].each { |member| member.skills_list = [ "first aid", "sommelier" ] }
      [ @alice, @carol ].each { |member| member.certifications_list = "A320" }
      [ @alice, @zoe, @carol ].each(&:save!)
      @carol.update_column(:airline_id, @zenith.id)
    end

    test "carol's tags belong to her previous scope" do
      assert_equal [ @acme.id ], CrewMemberTag.joins(:skill_taggings)
                                              .where(crew_member_taggings: { taggable_id: @carol.id })
                                              .distinct.pluck(:airline_id)
    end

    test "with_any only matches tags in the record's scope" do
      assert_equal [ @alice, @zoe ].to_set, CrewMember.with_any_skills("first aid").to_set
    end

    test "with_all only matches tags in the record's scope" do
      assert_equal [ @alice, @zoe ].to_set, CrewMember.with_all_skills("first aid", "sommelier").to_set
    end

    test "with_exact only matches tags in the record's scope" do
      assert_equal [ @alice, @zoe ].to_set, CrewMember.with_exact_skills("first aid", "sommelier").to_set
    end

    test "without_any treats tags from another scope as absent" do
      assert_equal [ @carol, @untagged ].to_set, CrewMember.without_any_skills("first aid").to_set
    end

    test "without treats tags from another scope as absent" do
      assert_equal [ @carol, @untagged ].to_set, CrewMember.without_skills.to_set
      assert_equal [ @carol, @untagged ].to_set, CrewMember.with_exact_skills([]).to_set
    end

    test "polymorphic queries only match tags in the record's scope" do
      assert_equal [ @alice ], CrewMember.with_any_certifications("A320").to_a
      assert_equal [ @alice ], CrewMember.with_all_certifications("A320").to_a
      assert_equal [ @zoe, @carol, @untagged ].to_set, CrewMember.without_certifications.to_set
      assert_equal [ @zoe, @carol, @untagged ].to_set, CrewMember.without_any_certifications("A320").to_set
    end

    test "saving the tag list again moves tags into the record's scope" do
      @carol.reload.skills_list = "first aid"
      @carol.save!

      assert_includes CrewMember.with_any_skills("first aid"), @carol
      assert_equal @zoe.skills.find_by(name: "first aid"), @carol.skills.first
    end
  end
end
