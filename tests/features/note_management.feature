Feature: Note management
  As a single self-hosted user
  I want to create, read, update and delete notes
  So that I can capture and maintain my knowledge

  Background:
    Given the Heddle app is running
    And the note store is empty

  Scenario: Create a new note
    When I create a note titled "Coffee Brewing" with body "Pour-over depends on water temperature."
    Then a note titled "Coffee Brewing" exists
    And the note has a stable id
    And viewing the note renders "Pour-over depends on water temperature." as HTML

  Scenario: Markdown is rendered in view mode
    Given a note titled "Styles" with body:
      """
      # Heading

      Some **bold** text and a list:

      - one
      - two
      """
    When I view the note "Styles"
    Then the rendered output contains a level-1 heading "Heading"
    And the rendered output contains bold text "bold"
    And the rendered output contains a list with items "one" and "two"

  Scenario: Edit a note's body
    Given a note titled "Coffee Brewing" with body "Old text."
    When I edit the note "Coffee Brewing" and set its body to "New text."
    Then viewing the note "Coffee Brewing" renders "New text."
    And the note's updated-at timestamp is newer than its created-at timestamp

  Scenario: A note's stable id is a UUIDv7
    When I create a note titled "Coffee Brewing" with body "Pour-over notes."
    Then the note's id is a valid UUIDv7

  Scenario: Timestamps are stored and exposed in UTC
    When I create a note titled "Coffee Brewing" with body "Pour-over notes."
    Then the note's created-at timestamp is in UTC
    And the note's updated-at timestamp is in UTC
    And both timestamps are formatted as RFC 3339 with a "Z" offset

  Scenario: Rename a note keeps its identity
    Given a note titled "Coffee Brewing" with body "Pour-over notes."
    When I rename the note "Coffee Brewing" to "Pour-over Notes"
    Then a note titled "Pour-over Notes" exists
    And no note titled "Coffee Brewing" exists
    And the note keeps the same stable id

  Scenario: Delete a note
    Given a note titled "Scratch" with body "temporary"
    When I delete the note "Scratch"
    Then no note titled "Scratch" exists

  Scenario: Titles are unique, case-insensitively
    Given a note titled "Coffee Brewing" with body "first"
    When I try to create a note titled "coffee brewing" with body "second"
    Then the creation is rejected with a "title already exists" error

  Scenario: Title display preserves the original casing
    When I create a note titled "Coffee Brewing" with body "x"
    Then the note's displayed title is exactly "Coffee Brewing"

  Scenario: An empty or whitespace-only title is rejected
    When I try to create a note titled "   " with body "x"
    Then the creation is rejected with an "empty title" error

  Scenario: Leading and trailing whitespace is trimmed from titles
    When I create a note titled "  Coffee Brewing  " with body "x"
    Then a note titled "Coffee Brewing" exists
    And the note's displayed title is exactly "Coffee Brewing"

  Scenario: A title of 1024 characters is accepted
    When I create a note whose title is 1024 characters long
    Then the note is created successfully

  Scenario: A title longer than 1024 characters is rejected
    When I try to create a note whose title is 1025 characters long
    Then the creation is rejected with a "title too long" error

  Scenario: Title length is counted in characters, not bytes
    When I create a note whose title is 1024 CJK characters long
    Then the note is created successfully
