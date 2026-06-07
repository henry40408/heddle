Feature: View and edit toggle
  As a user writing in Markdown
  I want each open note to switch between a rendered view and a raw editor
  So that I can read comfortably and edit deliberately

  Background:
    Given the Heddle app is running
    And a note titled "Coffee Brewing" with body "Pour-over depends on water temperature."

  Scenario: A note opens in view mode
    When I open the note "Coffee Brewing"
    Then the note "Coffee Brewing" is in view mode
    And it shows the rendered Markdown

  Scenario: Switching to edit mode shows raw Markdown
    Given the note "Coffee Brewing" is open in view mode
    When I switch the note "Coffee Brewing" to edit mode
    Then the editor shows the raw Markdown "Pour-over depends on water temperature."

  Scenario: Saving an edit persists and returns to view mode
    Given the note "Coffee Brewing" is open in edit mode
    When I set the editor body to "Bloom for 30 seconds." and save
    Then the note "Coffee Brewing" is in view mode
    And viewing the note "Coffee Brewing" renders "Bloom for 30 seconds."

  Scenario: Cancelling an edit discards changes
    Given the note "Coffee Brewing" is open in edit mode
    When I set the editor body to "Discard me." and cancel
    Then the note "Coffee Brewing" is in view mode
    And viewing the note "Coffee Brewing" renders "Pour-over depends on water temperature."

  Scenario: Edit mode is per note in the river
    Given the story river shows "Coffee Brewing" and "Brew Params"
    When I switch the note "Coffee Brewing" to edit mode
    Then the note "Coffee Brewing" is in edit mode
    And the note "Brew Params" is still in view mode
