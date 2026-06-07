Feature: Strand identity and common rules
  As a user of a non-linear web
  I want every strand to share the same identity and title rules
  So that notes and blobs behave consistently wherever type does not matter

  # A "strand" is any transcludable entity: a note or a blob. The rules here
  # hold for every strand regardless of type. Notes are created with text;
  # blobs are created by upload; both are strands. Type-specific behaviour
  # lives in note_management.feature and blob_transclusion.feature.

  Background:
    Given the Heddle app is running
    And the store is empty

  Scenario: Every strand has a UUIDv7 id
    When I create a note titled "Coffee Brewing" with body "x"
    And I upload the image "coffee-setup.png"
    Then the strand "Coffee Brewing" has an id that is a valid UUIDv7
    And the strand "coffee-setup.png" has an id that is a valid UUIDv7

  Scenario: Timestamps are stored and exposed in UTC
    When I create a note titled "Coffee Brewing" with body "x"
    Then the strand's created-at timestamp is in UTC
    And the strand's updated-at timestamp is in UTC
    And both timestamps are formatted as RFC 3339 with a "Z" offset

  Scenario: Titles are unique across all strands, case-insensitively
    Given a note titled "Coffee Brewing" with body "first"
    When I try to create a note titled "coffee brewing" with body "second"
    Then the creation is rejected with a "title already exists" error

  Scenario: A note and a blob cannot share a title
    Given a note titled "diagram" with body "x"
    When I try to upload a file named "Diagram"
    Then the upload is rejected with a "title already exists" error

  Scenario: Title display preserves the original casing
    When I create a note titled "Coffee Brewing" with body "x"
    Then the strand's displayed title is exactly "Coffee Brewing"

  Scenario: An empty or whitespace-only title is rejected
    When I try to create a note titled "   " with body "x"
    Then the creation is rejected with an "empty title" error

  Scenario: Leading and trailing whitespace is trimmed from titles
    When I create a note titled "  Coffee Brewing  " with body "x"
    Then a strand titled "Coffee Brewing" exists

  Scenario: A title of 1024 characters is accepted
    When I create a note whose title is 1024 characters long
    Then the strand is created successfully

  Scenario: A title longer than 1024 characters is rejected
    When I try to create a note whose title is 1025 characters long
    Then the creation is rejected with a "title too long" error

  Scenario: Title length is counted in characters, not bytes
    When I create a note whose title is 1024 CJK characters long
    Then the strand is created successfully
