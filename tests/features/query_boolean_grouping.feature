Feature: Boolean grouping in queries
  As a user expressing a complex filter
  I want parentheses and OR across different keys
  So that I can ask for things a flat key:value list cannot express

  # The flat surface (structured_query.feature) keeps space=AND and lets a
  # comma OR values *within one key*. To OR across *different* keys, or to nest
  # groups, the surface adds "( )" and the "OR" keyword. Space (or an explicit
  # "AND") still binds tighter than "OR", so "a b OR c" parses as "(a AND b)
  # OR c"; use parentheses to override. Simple queries never need parentheses.
  # Grouping changes only the parse tree handed to the operator pipeline -- the
  # engine itself is unchanged.

  Background:
    Given the Heddle app is running
    And the store is empty
    And the following notes exist:
      | title          | body | tags          |
      | Coffee Brewing | x    | coffee        |
      | Tea Notes      | x    | tea           |
      | Morning Pages  | x    | coffee,tea    |
      | Garden Log     | x    | outdoors      |
    And an uploaded pdf "scale-manual.pdf" tagged "tea"

  Scenario: OR across two different keys
    When I run the query "tag:coffee OR type:pdf"
    Then the query results include "Coffee Brewing"
    And the query results include the blob "scale-manual.pdf"
    And the query results do not include "Garden Log"

  Scenario: Parentheses group an OR before an outer AND
    When I run the query "(tag:coffee OR type:pdf) tag:tea"
    Then the query results include "Morning Pages"
    And the query results include the blob "scale-manual.pdf"
    And the query results do not include "Coffee Brewing"

  Scenario: The worked example with two OR groups
    Given a note titled "Daily Brew" with body "x" tagged "coffee" created today
    When I run the query "(tag:coffee OR created:today) (tag:tea OR type:pdf)"
    Then the query results include "Morning Pages"
    And the query results include the blob "scale-manual.pdf"
    And the query results do not include "Coffee Brewing"

  Scenario: An explicit AND keyword equals a space
    When I run the query "tag:coffee AND tag:tea"
    Then the query results include "Morning Pages"
    And the query results do not include "Coffee Brewing"

  Scenario: AND binds tighter than OR without parentheses
    When I run the query "tag:coffee tag:tea OR tag:outdoors"
    Then the query results include "Morning Pages"
    And the query results include "Garden Log"
    And the query results do not include "Coffee Brewing"

  Scenario: Unbalanced parentheses report a friendly error
    When I run the query "(tag:coffee OR tag:tea"
    Then the query is rejected with an "unbalanced parentheses" error
