Feature: Editable property cells in views
  As a user keeping a dashboard
  I want to change a strand's property from within a template view
  So that I can run a board without opening each source strand in turn

  # By default a property interpolation "{{ it.field }}" in a template strand renders
  # read-only (properties.feature, dynamic_transclusion.feature). A Liquid-style
  # pipe modifier "{{ it.field | edit }}" opts that one cell into being editable: it
  # renders the same type-appropriate editor the panel uses (a dropdown for
  # select, a checkbox for boolean, and so on) and writes the new value straight
  # back to that row's source strand. Because each row IS a strand with an id,
  # the write-back is well defined ("set property P of strand S").
  #
  # "edit" is the only modifier for now. The pipe is the same bounded mechanism
  # Liquid uses: a chain of value-to-value transforms (e.g. a future "| upcase"
  # or "| date") plus this one behaviour flag. It cannot express control flow --
  # a loop or conditional is not a filter -- so it stays non-Turing-complete and
  # never grows into a full widget/block language with its own control flow and
  # composable components; that larger step would be a separate decision.
  # Everything without a "| edit" stays read-only, so a dashboard is editable
  # only exactly where its author intends.

  Background:
    Given the Heddle app is running
    And the store is empty
    And the property "stage" is defined as select with options "todo, doing, done"
    And the property "done" is defined as boolean
    And the property "roast" is defined as text

  Scenario: A marked cell renders an editable editor of the property's type
    Given a note titled "Coffee Brewing" with property "stage" set to "doing" tagged "coffee"
    And a note titled "Row" with body "{{ it.title }} - {{ it.stage | edit }}"
    And a note titled "Board" with body "{% query "tag:coffee" template="Row" %}"
    When I view the note "Board"
    Then the "stage" cell for "Coffee Brewing" is an editable dropdown
    And that dropdown's current value is "doing"

  Scenario: An editable select cell offers exactly the property's options
    Given a note titled "Coffee Brewing" with property "stage" set to "doing" tagged "coffee"
    And a note titled "Row" with body "{{ it.title }} - {{ it.stage | edit }}"
    And a note titled "Board" with body "{% query "tag:coffee" template="Row" %}"
    When I view the note "Board"
    Then the "stage" cell for "Coffee Brewing" offers only "todo", "doing" and "done"

  Scenario: Editing a cell writes back to its source strand
    Given a note titled "Coffee Brewing" with property "stage" set to "doing" tagged "coffee"
    And a note titled "Row" with body "{{ it.title }} - {{ it.stage | edit }}"
    And a note titled "Board" with body "{% query "tag:coffee" template="Row" %}"
    And I am viewing the note "Board"
    When I set the "stage" cell for "Coffee Brewing" to "done"
    Then the strand "Coffee Brewing" has property "stage" equal to "done"

  Scenario: An unmarked cell in the same row stays read-only
    Given a note titled "Coffee Brewing" with property "stage" set to "doing" tagged "coffee"
    And the note "Coffee Brewing" has property "roast" set to "light"
    And a note titled "Row" with body "{{ it.roast }} - {{ it.stage | edit }}"
    And a note titled "Board" with body "{% query "tag:coffee" template="Row" %}"
    When I view the note "Board"
    Then the "roast" cell for "Coffee Brewing" is read-only text showing "light"
    And the "stage" cell for "Coffee Brewing" is an editable dropdown

  Scenario: A marked boolean cell renders an editable checkbox
    Given a note titled "Buy Beans" with property "done" set to "false" tagged "todo"
    And a note titled "Row" with body "{{ it.title }} {{ it.done | edit }}"
    And a note titled "Board" with body "{% query "tag:todo" template="Row" %}"
    And I am viewing the note "Board"
    When I tick the "done" cell for "Buy Beans"
    Then the strand "Buy Beans" has property "done" equal to true

  Scenario: Editing one row leaves sibling rows untouched
    Given a note titled "Coffee Brewing" with property "stage" set to "doing" tagged "coffee"
    And a note titled "Aeropress Test" with property "stage" set to "doing" tagged "coffee"
    And a note titled "Row" with body "{{ it.title }} - {{ it.stage | edit }}"
    And a note titled "Board" with body "{% query "tag:coffee" template="Row" %}"
    And I am viewing the note "Board"
    When I set the "stage" cell for "Coffee Brewing" to "done"
    Then the strand "Coffee Brewing" has property "stage" equal to "done"
    And the strand "Aeropress Test" has property "stage" equal to "doing"

  Scenario: The row's literal template text is never editable
    Given a note titled "Coffee Brewing" with property "stage" set to "doing" tagged "coffee"
    And a note titled "Row" with body "Status: {{ it.stage | edit }}"
    And a note titled "Board" with body "{% query "tag:coffee" template="Row" %}"
    When I view the note "Board"
    Then the literal text "Status:" offers no editing
    And only the "stage" cell is interactive
    And the row offers a "go to source" action that opens the note "Coffee Brewing"
