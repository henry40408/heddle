Feature: Dynamic transclusion
  As a user who wants live views over my web
  I want to embed the result of a query, not just one named strand
  So that a note can show an always-current list assembled from many strands

  # Static "{{Title}}" embeds one named strand (transclusion.feature). Dynamic
  # transclusion uses triple braces "{{{ query }}}" to embed the *result* of a
  # query (structured_query.feature). Two rendering tiers:
  #   Tier A -- "{{{ query }}}" renders a built-in list of matching strands.
  #   Tier B -- "{{{ query || Template }}}" renders each match through a
  #             template strand whose body uses "{{.field}}" to interpolate the
  #             match's own fields (title, tags, properties). ".title" is always
  #             available; other fields come from properties.feature.
  # Like static transclusion the embedded view is read-only and offers
  # go-to-source on each item; it re-resolves whenever its inputs change.

  Background:
    Given the Heddle app is running
    And the store is empty
    And the following notes exist:
      | title          | body | tags   |
      | Coffee Brewing | x    | coffee |
      | Pour Over      | x    | coffee |
      | Garden Log     | x    | garden |

  Scenario: A query embed renders a live list of matches
    Given a note titled "Coffee Index" with body "{{{ tag:coffee }}}"
    When I view the note "Coffee Index"
    Then the rendered output lists "Coffee Brewing"
    And the rendered output lists "Pour Over"
    And the rendered output does not list "Garden Log"

  Scenario: The list updates when a new matching strand appears
    Given a note titled "Coffee Index" with body "{{{ tag:coffee }}}"
    And I have viewed the note "Coffee Index"
    When I create a note titled "Aeropress" with body "x" tagged "coffee"
    And I view the note "Coffee Index"
    Then the rendered output lists "Aeropress"

  Scenario: An empty result shows an empty-state, not an error
    Given a note titled "Empty Index" with body "{{{ tag:nonexistent }}}"
    When I view the note "Empty Index"
    Then the rendered output shows an empty-result placeholder
    And the page does not show an error

  Scenario: Each listed item is read-only and offers go-to-source
    Given a note titled "Coffee Index" with body "{{{ tag:coffee }}}"
    When I view the note "Coffee Index"
    Then the listed item "Coffee Brewing" offers no inline editing
    And it offers a "go to source" action that opens the note "Coffee Brewing"

  Scenario: A template renders each match through a template strand
    Given a note titled "Card" with body:
      """
      ## {{.title}}
      tagged: {{.tags}}
      """
    And a note titled "Coffee Cards" with body "{{{ tag:coffee || Card }}}"
    When I view the note "Coffee Cards"
    Then the rendered output contains "## Coffee Brewing"
    And the rendered output contains "## Pour Over"
    And the rendered output does not contain "{{.title}}"

  Scenario: A template can interpolate a property of each match
    Given the property "roast" is defined as text
    And the note "Coffee Brewing" has property "roast" set to "light"
    And a note titled "Row" with body "{{.title}}: {{.roast}}"
    And a note titled "Roast Table" with body "{{{ tag:coffee || Row }}}"
    When I view the note "Roast Table"
    Then the rendered output contains "Coffee Brewing: light"

  Scenario: A missing template strand shows a generic placeholder
    Given a note titled "Coffee Cards" with body "{{{ tag:coffee || Ghost Template }}}"
    When I view the note "Coffee Cards"
    Then the embed shows a "missing source: Ghost Template" placeholder

  Scenario: A malformed embedded query shows a placeholder, not a crash
    Given a note titled "Broken Index" with body "{{{ tag: }}}"
    When I view the note "Broken Index"
    Then the embed shows a "missing value for tag" placeholder
    And the page does not hang
