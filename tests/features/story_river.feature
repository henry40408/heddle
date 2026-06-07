Feature: Story river navigation
  As a non-linear note taker
  I want clicked strands to stack open in a central column
  So that I can read several related strands side by side

  # The river holds strands of any type: notes open as editable views, blobs
  # open as read-only viewers (image / PDF / download).

  Background:
    Given the Heddle app is running
    And the following notes exist:
      | title           | body                          |
      | Coffee Brewing  | I follow [[Pour-over Notes]]. |
      | Pour-over Notes | Ratio 1:16.                   |
      | Cafe Log        | Notes from today.             |
    And an uploaded image "coffee-setup.png"

  Scenario: Opening a note adds it to the river
    Given the story river is empty
    When I open the note "Coffee Brewing"
    Then the story river shows "Coffee Brewing"

  Scenario: Opening a blob adds it to the river as a read-only viewer
    Given the story river is empty
    When I open the blob "coffee-setup.png"
    Then the story river shows "coffee-setup.png"
    And "coffee-setup.png" opens as a read-only viewer

  Scenario: Following a link stacks the target strand
    Given I have the note "Coffee Brewing" open
    When I click the link "Pour-over Notes"
    Then the story river shows "Coffee Brewing" and "Pour-over Notes"
    And "Pour-over Notes" is positioned after "Coffee Brewing"

  Scenario: Closing a strand removes it from the river
    Given the story river shows "Coffee Brewing" and "Pour-over Notes"
    When I close "Pour-over Notes" in the river
    Then the story river shows "Coffee Brewing"
    And the story river does not show "Pour-over Notes"

  Scenario: Opening an already-open strand does not duplicate it
    Given the story river shows "Coffee Brewing"
    When I open the note "Coffee Brewing"
    Then the story river shows "Coffee Brewing" exactly once
    And "Coffee Brewing" is scrolled into view
