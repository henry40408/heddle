Feature: Wiki links and backlinks
  As a user building a non-linear web of notes
  I want [[Title]] links and automatic backlinks
  So that notes connect to each other in both directions

  Background:
    Given the Heddle app is running
    And the note store is empty

  Scenario: A wiki link to an existing note resolves
    Given a note titled "Pour-over Notes" with body "details"
    And a note titled "Morning Ritual" with body "I follow [[Pour-over Notes]] every day."
    When I view the note "Morning Ritual"
    Then the text "Pour-over Notes" is rendered as a link to the note "Pour-over Notes"

  Scenario: Wiki link resolution is case-insensitive
    Given a note titled "Pour-over Notes" with body "details"
    And a note titled "Morning Ritual" with body "I follow [[pour-over notes]] every day."
    When I view the note "Morning Ritual"
    Then the text "pour-over notes" is rendered as a link to the note "Pour-over Notes"

  Scenario: A wiki link to a missing note is shown as a missing link
    Given a note titled "Morning Ritual" with body "See [[Nonexistent]]."
    When I view the note "Morning Ritual"
    Then the text "Nonexistent" is rendered as a missing link

  Scenario: Clicking a missing link creates the note
    Given a note titled "Morning Ritual" with body "See [[Nonexistent]]."
    And I am viewing the note "Morning Ritual"
    When I click the missing link "Nonexistent"
    Then a note titled "Nonexistent" exists
    And the note "Nonexistent" opens for editing

  Scenario: Backlinks list referencing notes
    Given a note titled "Pour-over Notes" with body "details"
    And a note titled "Morning Ritual" with body "I follow [[Pour-over Notes]]."
    And a note titled "Cafe Log" with body "Used [[Pour-over Notes]] today."
    When I view the note "Pour-over Notes"
    Then the backlinks panel lists "Morning Ritual"
    And the backlinks panel lists "Cafe Log"

  Scenario: Renaming a note updates links that point to it
    Given a note titled "Pour-over Notes" with body "details"
    And a note titled "Morning Ritual" with body "I follow [[Pour-over Notes]]."
    When I rename the note "Pour-over Notes" to "Hand Pour"
    And I view the note "Morning Ritual"
    Then the text "Hand Pour" is rendered as a link to the note "Hand Pour"
    And there are no missing links in "Morning Ritual"

  Scenario: Backlinks update when a link is removed
    Given a note titled "Pour-over Notes" with body "details"
    And a note titled "Morning Ritual" with body "I follow [[Pour-over Notes]]."
    When I edit the note "Morning Ritual" and set its body to "No link anymore."
    And I view the note "Pour-over Notes"
    Then the backlinks panel does not list "Morning Ritual"
