# frozen_string_literal: true

require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  include NoFlyList::TestHelper

  fixtures :people, :person_tags

  test 'assert_taggable_record' do
    assert_taggable_record(Person, :pronouns)
  end

  should have_many(:pronoun_taggings)
  should have_many(:pronouns).through(:pronoun_taggings)

  test 'pronoun addition validation' do
    person = people(:john_doe)
    pronouns_list = person.pronouns_list

    assert_equal 0, person.pronouns.count

    # Add valid pronoun
    pronouns_list.add('he')
    assert pronouns_list.save

    # Validate pronoun list count
    assert_equal 1, pronouns_list.count
    assert_equal 1, pronouns_list.size

    # Attempt to add invalid pronoun
    pronouns_list.add('where')
    refute pronouns_list.save

    # Confirm invalid pronoun rejection
    assert_equal 1, pronouns_list.count
    assert_equal 'The following tags do not exist: where', pronouns_list.errors.full_messages.first
  end

  test 'restrict pronoun addition limit' do
    person = people(:jane_smith)

    assert_equal 0, person.pronouns.count

    # Set pronouns
    person.pronouns_list = 'she/her'
    assert person.pronouns_list.save

    # Validate pronoun list count
    assert_equal 2, person.pronouns_list.size

    # Print back pronouns
    assert_equal 'she/her', person.pronouns_list.to_s
  end
end
