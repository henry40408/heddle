Feature: Full-text search
  As a user with many notes
  I want to search note titles and bodies
  So that I can find and open notes quickly

  Background:
    Given the Heddle app is running
    And the following notes exist:
      | title          | body                              |
      | Coffee Brewing | Pour-over depends on water temp.  |
      | Brew Params    | Ratio 1:16, water 92C.            |
      | Garden Log     | Watered the tomatoes today.       |

  Scenario: Search matches note bodies
    When I search for "water"
    Then the search results include "Coffee Brewing"
    And the search results include "Brew Params"
    And the search results include "Garden Log"

  Scenario: Search matches note titles
    When I search for "brew"
    Then the search results include "Coffee Brewing"
    And the search results include "Brew Params"

  Scenario: Search with no matches returns nothing
    When I search for "espresso"
    Then the search results are empty

  Scenario: Opening a search result adds it to the river
    Given I searched for "tomatoes"
    When I open the search result "Garden Log"
    Then the story river shows "Garden Log"

  Scenario: Newly created content becomes searchable
    Given a note titled "Tea Notes" with body "Steep oolong for three minutes."
    When I search for "oolong"
    Then the search results include "Tea Notes"
