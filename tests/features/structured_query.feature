Feature: Structured query language
  As a user with a growing non-linear web
  I want a Gmail-style key:value query over my strands
  So that I can narrow down notes and blobs without learning a programming language

  # This is the query *surface*: a search box where bare words do full-text
  # matching (see search.feature) and "key:value" terms filter by a known
  # operator. A space between terms means AND. A comma inside one key's value
  # means OR within that key. A leading "-" excludes. Reserved keys are the
  # built-in operators below; any other key falls through to a property lookup
  # (see properties.feature). Values are matched case-insensitively, like tags
  # and titles. The surface compiles to a composable operator pipeline, so the
  # boolean grouping in query_boolean_grouping.feature reuses the same engine.

  Background:
    Given the Heddle app is running
    And the store is empty
    And the following notes exist:
      | title          | body                             | tags           |
      | Coffee Brewing | Pour-over depends on water temp. | coffee,morning |
      | Tea Notes      | Steep oolong three minutes.      | tea,morning    |
      | Garden Log     | Watered the tomatoes today.      | outdoors       |
    And an uploaded image "coffee-setup.png" tagged "coffee,gear"
    And an uploaded pdf "scale-manual.pdf" tagged "gear"

  Scenario: A single key:value term filters by that operator
    When I run the query "tag:coffee"
    Then the query results include "Coffee Brewing"
    And the query results include the blob "coffee-setup.png"
    And the query results do not include "Tea Notes"

  Scenario: A space between terms means AND
    When I run the query "tag:coffee tag:morning"
    Then the query results include "Coffee Brewing"
    And the query results do not include the blob "coffee-setup.png"

  Scenario: A comma inside one key means OR within that key
    When I run the query "tag:coffee,tea"
    Then the query results include "Coffee Brewing"
    And the query results include "Tea Notes"
    And the query results do not include "Garden Log"

  Scenario: A leading minus excludes matches
    When I run the query "tag:morning -tag:coffee"
    Then the query results include "Tea Notes"
    And the query results do not include "Coffee Brewing"

  Scenario: The type operator filters by strand kind
    When I run the query "type:note"
    Then the query results include "Coffee Brewing"
    And the query results do not include the blob "coffee-setup.png"

  Scenario: The type operator distinguishes blob kinds
    When I run the query "type:pdf"
    Then the query results include the blob "scale-manual.pdf"
    And the query results do not include the blob "coffee-setup.png"

  Scenario: The title operator matches on title substring
    When I run the query "title:coffee"
    Then the query results include "Coffee Brewing"
    And the query results do not include "Tea Notes"

  Scenario: A relative date operator resolves against the current day
    Given a note titled "Today Standup" with body "x" created today
    And a note titled "Old Meeting" with body "x" created last week
    When I run the query "created:today"
    Then the query results include "Today Standup"
    And the query results do not include "Old Meeting"

  Scenario: A bare word combines full-text search with operators
    When I run the query "water tag:coffee"
    Then the query results include "Coffee Brewing"
    And the query results do not include the blob "coffee-setup.png"

  Scenario: Operator values are matched case-insensitively
    When I run the query "tag:COFFEE"
    Then the query results include "Coffee Brewing"

  Scenario: An unknown key is treated as a property query
    When I run the query "status:done"
    Then the query is accepted without error
    And the query is interpreted as filtering on the property "status"

  Scenario: A malformed query reports a friendly error
    When I run the query "tag:"
    Then the query is rejected with a "missing value for tag" error
