Feature: Note management
  As a single self-hosted user
  I want to create, read, update and delete notes
  So that I can capture and maintain my knowledge

  # Rules shared by every strand (UUIDv7 id, UTC timestamps, title uniqueness
  # and formatting) live in strand_common.feature. This file covers behaviour
  # specific to notes: Markdown authoring, rendering, and the text body.

  Background:
    Given the Heddle app is running
    And the note store is empty

  Scenario: Create a new note
    When I create a note titled "Coffee Brewing" with body "Pour-over depends on water temperature."
    Then a note titled "Coffee Brewing" exists
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
