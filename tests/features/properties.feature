Feature: Structured properties
  As a user who wants more than free text
  I want typed key/value properties on any strand
  So that I can record status, ratings, dates and the like, then query them

  # Properties are structured metadata edited through a panel, not written into
  # the note body. They live in the database, so notes and blobs carry them
  # uniformly (a blob has no body to hold frontmatter). The body stays clean
  # Markdown. A light schema registry records each property's name and type;
  # values are validated against that type. Types: text, number,
  # boolean, date, select, multi-select. Property keys share the query
  # namespace with the reserved operators -- an unknown query key is a property
  # lookup (structured_query.feature).
  #
  # The panel renders a type-appropriate editor for each property -- a checkbox
  # for boolean, a dropdown for select, a number input for number, a date
  # picker for date -- so there is no widget syntax in the body. In template and
  # dynamic views (dynamic_transclusion.feature) a property is shown read-only
  # via "{{.field}}"; to change it you edit the source strand's panel, or mark
  # the cell editable with "{{.field | edit}}" (editable_cells.feature).

  Background:
    Given the Heddle app is running
    And the store is empty
    And a note titled "Coffee Brewing" with body "Pour-over notes."
    And an uploaded image "coffee-setup.png"

  Scenario: Set a property on a note through the panel
    Given the property "status" is defined as text
    When I set the property "status" of "Coffee Brewing" to "doing"
    Then the strand "Coffee Brewing" has property "status" equal to "doing"

  Scenario: Set a property on a blob through the panel
    Given the property "status" is defined as text
    When I set the property "status" of "coffee-setup.png" to "archived"
    Then the strand "coffee-setup.png" has property "status" equal to "archived"

  Scenario: Properties do not appear in the note body
    Given the property "status" is defined as text
    When I set the property "status" of "Coffee Brewing" to "doing"
    Then the body of "Coffee Brewing" is still "Pour-over notes."
    And the body of "Coffee Brewing" does not contain "status"

  Scenario: A number property rejects a non-number value
    Given the property "rating" is defined as number
    When I try to set the property "rating" of "Coffee Brewing" to "tasty"
    Then the property update is rejected with a "not a number" error

  Scenario: A boolean property accepts true and false
    Given the property "done" is defined as boolean
    When I set the property "done" of "Coffee Brewing" to "true"
    Then the strand "Coffee Brewing" has property "done" equal to true

  Scenario: A date property is stored in UTC RFC 3339
    Given the property "due" is defined as date
    When I set the property "due" of "Coffee Brewing" to "2026-06-30"
    Then the property "due" of "Coffee Brewing" is stored as an RFC 3339 timestamp with a "Z" offset

  Scenario: A select property constrains values to its options
    Given the property "stage" is defined as select with options "todo, doing, done"
    When I set the property "stage" of "Coffee Brewing" to "doing"
    Then the strand "Coffee Brewing" has property "stage" equal to "doing"

  Scenario: A select property rejects a value outside its options
    Given the property "stage" is defined as select with options "todo, doing, done"
    When I try to set the property "stage" of "Coffee Brewing" to "blocked"
    Then the property update is rejected with a "not an allowed option" error

  Scenario: A multi-select property holds several values
    Given the property "moods" is defined as multi-select with options "bright, bold, sweet"
    When I set the property "moods" of "Coffee Brewing" to "bright, sweet"
    Then the strand "Coffee Brewing" has property "moods" containing "bright" and "sweet"

  Scenario: Remove a property
    Given the property "status" is defined as text
    And the note "Coffee Brewing" has property "status" set to "doing"
    When I clear the property "status" of "Coffee Brewing"
    Then the strand "Coffee Brewing" has no property "status"

  Scenario: The panel renders a type-appropriate editor for each property
    Given the property "stage" is defined as select with options "todo, doing, done"
    And the property "rating" is defined as number
    And the property "due" is defined as date
    And the property "done" is defined as boolean
    When I open the properties panel of "Coffee Brewing"
    Then the editor for "stage" is a dropdown
    And the editor for "rating" is a number input
    And the editor for "due" is a date picker
    And the editor for "done" is a checkbox

  Scenario: A select editor offers exactly the defined options
    Given the property "stage" is defined as select with options "todo, doing, done"
    When I open the properties panel of "Coffee Brewing"
    Then the "stage" editor offers only "todo", "doing" and "done"

  Scenario: A property is read-only in a template view
    Given the property "stage" is defined as select with options "todo, doing, done"
    And the note "Coffee Brewing" has property "stage" set to "doing"
    And a note titled "Row" with body "{{.title}}: {{.stage}}"
    And a note titled "Board" with body "{{{ stage:doing || Row }}}"
    When I view the note "Board"
    Then the rendered output contains "Coffee Brewing: doing"
    And the template view offers no editor for "stage"

  Scenario: Query by an equality property
    Given the property "status" is defined as text
    And the note "Coffee Brewing" has property "status" set to "done"
    And a note titled "Tea Notes" with body "x"
    When I run the query "status:done"
    Then the query results include "Coffee Brewing"
    And the query results do not include "Tea Notes"

  Scenario: Query a number property with a comparison
    Given the property "rating" is defined as number
    And the note "Coffee Brewing" has property "rating" set to "5"
    And a note titled "Weak Cup" with property "rating" set to "2"
    When I run the query "rating:>4"
    Then the query results include "Coffee Brewing"
    And the query results do not include "Weak Cup"
