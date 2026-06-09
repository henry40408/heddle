Feature: Ordering a dynamic embed with sort
  As a user assembling a dashboard from a query
  I want to control the order of the matched strands
  So that a list reads top-to-bottom the way I expect, not in arbitrary order

  # A bare "{% query "<query>" %}" (dynamic_transclusion.feature) lists matches in
  # an unspecified order, which makes any board or "latest N" view unusable. The
  # "sort" operator fixes the order. It is a PIPELINE operator that lives INSIDE
  # the query string, not an attribute on the query tag: ordering is therefore
  # expressed in exactly one place (the query AST, structured_query.feature), and
  # "{% query %}" stays a thin wrapper. So:
  #     {% query "tag:coffee sort:title" %}        -- filter, then order by title
  #     {% query "tag:coffee sort:-rating" %}      -- filter, then order by rating, descending
  #
  # Direction: "sort:key" is ascending; a leading "-" ON THE VALUE
  # ("sort:-key") is descending. This minus sits on the value and reverses the
  # order; it is distinct from the query language's leading "-" on a whole term
  # ("-tag:coffee", structured_query.feature), which excludes matches. Position
  # disambiguates them.
  #
  # Comparison is TYPE-DRIVEN from the property schema (properties.feature):
  # a number property sorts numerically, a date property chronologically, and
  # text -- or a built-in field like "title" with no schema type -- sorts
  # case-insensitively as a string. There is no separate numeric-sort operator
  # (TW5's "nsort"); the type registry already knows whether a key is a number.
  #
  # Determinism: ties on the sort key break by title (case-insensitive), so the
  # output order is total and the scenarios below can assert it. Strands that
  # lack the sort key entirely sort AFTER all strands that have it, regardless of
  # direction (missing is not "smallest"); among themselves they break by title.
  #
  # Only a single sort key is defined here. Multiple keys
  # ("sort:stage sort:title") are a deliberate later step (YAGNI).

  Background:
    Given the Heddle app is running
    And the store is empty
    And the property "rating" is defined as number
    And the property "due" is defined as date
    And the following notes exist:
      | title          | body | tags   |
      | Coffee Brewing | x    | coffee |
      | Aeropress Test | x    | coffee |
      | Pour Over      | x    | coffee |

  Scenario: Sorting by title orders matches case-insensitively ascending
    Given a note titled "Coffee Index" with body "{% query "tag:coffee sort:title" %}"
    When I view the note "Coffee Index"
    Then the rendered list order is "Aeropress Test", "Coffee Brewing", "Pour Over"

  Scenario: A leading minus on the value sorts descending
    Given a note titled "Coffee Index" with body "{% query "tag:coffee sort:-title" %}"
    When I view the note "Coffee Index"
    Then the rendered list order is "Pour Over", "Coffee Brewing", "Aeropress Test"

  Scenario: A number property sorts numerically, not lexicographically
    Given the note "Coffee Brewing" has property "rating" set to "2"
    And the note "Aeropress Test" has property "rating" set to "10"
    And the note "Pour Over" has property "rating" set to "5"
    And a note titled "Rating Board" with body "{% query "tag:coffee sort:rating" %}"
    When I view the note "Rating Board"
    Then the rendered list order is "Coffee Brewing", "Pour Over", "Aeropress Test"

  Scenario: A date property sorts chronologically
    Given the note "Coffee Brewing" has property "due" set to "2026-06-30"
    And the note "Aeropress Test" has property "due" set to "2026-01-05"
    And the note "Pour Over" has property "due" set to "2026-03-12"
    And a note titled "Due Board" with body "{% query "tag:coffee sort:due" %}"
    When I view the note "Due Board"
    Then the rendered list order is "Aeropress Test", "Pour Over", "Coffee Brewing"

  Scenario: A tie on the sort key breaks by title
    Given the note "Coffee Brewing" has property "rating" set to "5"
    And the note "Pour Over" has property "rating" set to "5"
    And the note "Aeropress Test" has property "rating" set to "5"
    And a note titled "Rating Board" with body "{% query "tag:coffee sort:rating" %}"
    When I view the note "Rating Board"
    Then the rendered list order is "Aeropress Test", "Coffee Brewing", "Pour Over"

  Scenario: Strands missing the sort key sort after those that have it
    Given the note "Coffee Brewing" has property "rating" set to "5"
    And the note "Pour Over" has property "rating" set to "1"
    And a note titled "Rating Board" with body "{% query "tag:coffee sort:rating" %}"
    When I view the note "Rating Board"
    Then the rendered list order is "Pour Over", "Coffee Brewing", "Aeropress Test"

  Scenario: Sort order is preserved when matches render through a template
    Given the note "Coffee Brewing" has property "rating" set to "2"
    And the note "Aeropress Test" has property "rating" set to "10"
    And the note "Pour Over" has property "rating" set to "5"
    And a note titled "Row" with body "{{ it.title }} ({{ it.rating }})"
    And a note titled "Rating Board" with body "{% query "tag:coffee sort:-rating" template="Row" %}"
    When I view the note "Rating Board"
    Then the rendered output contains "Aeropress Test (10)" before "Pour Over (5)"
    And the rendered output contains "Pour Over (5)" before "Coffee Brewing (2)"

  Scenario: Sorting an empty result shows the empty-state, not an error
    Given a note titled "Empty Index" with body "{% query "tag:nonexistent sort:title" %}"
    When I view the note "Empty Index"
    Then the rendered output shows an empty-result placeholder
    And the page does not show an error

  Scenario: Sort with no key reports a friendly error
    Given a note titled "Broken Index" with body "{% query "tag:coffee sort:" %}"
    When I view the note "Broken Index"
    Then the embed shows a "missing value for sort" placeholder
    And the page does not hang
