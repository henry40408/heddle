Feature: Tagging strands
  As a user organising a non-linear web
  I want to tag any strand, whether a note or a blob
  So that I can group and find related content across types

  # A "strand" is any transcludable entity: a note or a blob. Tags are
  # metadata on the strand, not inline #hashtags in the body -- so they
  # apply uniformly to blobs (which have no text body) and never collide
  # with Markdown "# heading" syntax. Tag matching is case-insensitive,
  # like titles.

  Background:
    Given the Heddle app is running
    And the store is empty

  Scenario: Tag a note
    Given a note titled "Coffee Brewing" with body "x"
    When I tag the strand "Coffee Brewing" with "beverage"
    Then the strand "Coffee Brewing" has the tag "beverage"

  Scenario: Tag a blob
    Given an uploaded image "coffee-setup.png"
    When I tag the strand "coffee-setup.png" with "gear"
    Then the strand "coffee-setup.png" has the tag "gear"

  Scenario: A strand can carry multiple tags
    Given a note titled "Coffee Brewing" with body "x"
    When I tag the strand "Coffee Brewing" with "beverage"
    And I tag the strand "Coffee Brewing" with "morning"
    Then the strand "Coffee Brewing" has the tags "beverage" and "morning"

  Scenario: Remove a tag
    Given a note titled "Coffee Brewing" tagged "beverage" and "morning"
    When I remove the tag "morning" from the strand "Coffee Brewing"
    Then the strand "Coffee Brewing" has the tag "beverage"
    And the strand "Coffee Brewing" does not have the tag "morning"

  Scenario: Listing by tag spans notes and blobs
    Given a note titled "Coffee Brewing" tagged "gear"
    And an uploaded image "coffee-setup.png" tagged "gear"
    And a note titled "Garden Log" tagged "outdoors"
    When I list strands tagged "gear"
    Then the results include the note "Coffee Brewing"
    And the results include the blob "coffee-setup.png"
    And the results do not include "Garden Log"

  Scenario: Tag matching is case-insensitive
    Given a note titled "Coffee Brewing" with body "x"
    When I tag the strand "Coffee Brewing" with "Beverage"
    And I list strands tagged "beverage"
    Then the results include the note "Coffee Brewing"

  Scenario: Re-tagging in a different case does not duplicate
    Given a note titled "Coffee Brewing" tagged "Beverage"
    When I tag the strand "Coffee Brewing" with "beverage"
    Then the strand "Coffee Brewing" has exactly one tag

  Scenario: An empty or whitespace-only tag is rejected
    Given a note titled "Coffee Brewing" with body "x"
    When I try to tag the strand "Coffee Brewing" with "   "
    Then the tagging is rejected with an "empty tag" error

  Scenario: Leading and trailing whitespace is trimmed from tags
    Given a note titled "Coffee Brewing" with body "x"
    When I tag the strand "Coffee Brewing" with "  beverage  "
    Then the strand "Coffee Brewing" has the tag "beverage"

  Scenario: Deleting a strand removes it from tag listings
    Given a note titled "Coffee Brewing" tagged "beverage"
    When I delete the strand "Coffee Brewing"
    And I list strands tagged "beverage"
    Then the results are empty
