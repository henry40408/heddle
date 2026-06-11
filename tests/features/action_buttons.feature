Feature: Action buttons
  As a user who builds small tools inside my notes
  I want a button in a template that performs a declared set of writes
  So that I can act on my web -- capture, file, update -- without opening each strand by hand

  # Templates render read-only by default (transclusion.feature,
  # dynamic_transclusion.feature), with one narrow exception for editable
  # property cells (editable_cells.feature). An action button is the one place a
  # template may *write*. It stays deliberately bounded:
  #   - A fixed, small verb set -- "create ", "set", "delete"
  #     (delete_action.feature) -- listed in order. The list is NOT control flow:
  #     no loops, no conditionals. Each action is "verb <target> key=value ...":
  #     one POSITIONAL target naming the strand acted on (a quoted "Title", a
  #     "{{ ... }}" interpolation, or a capture_form-bound alias like "scratch"),
  #     followed by zero or more KEYWORD arguments. A value takes one of three
  #     forms, told apart by syntax: a LITERAL string -- a bareword (body=hello)
  #     or a quoted string (body="hello world"), quoted only when it must contain
  #     whitespace or a special character; a "{{ ... }}" EXPRESSION, evaluated
  #     when the button is pressed (so it sees current state, not render-time
  #     state); or a "[...]" LIST literal for a multi-valued field. "{{ ... }}"
  #     is the only marker for "evaluate this", so a bareword is always a literal,
  #     never a variable. Inside a list, COMMA is the sole separator: each item is
  #     a bareword or quoted literal (or a "{{ }}" expression), whitespace inside
  #     an item is kept ([New York, NY] is two items, no quotes), and an item is
  #     quoted only to embed a comma (["a,b", c] is two items). "create "
  #     makes a note; "set" writes fields of the target; "delete" removes it.
  #   - Writes happen ONLY on an explicit user click. Merely viewing a note that
  #     contains a button never mutates anything -- viewing stays safe and
  #     idempotent, like every other rendered view.
  #   - A button's actions run as a single all-or-nothing transaction. If any
  #     action fails, none are applied, so a later "set"/clear can never destroy
  #     data after an earlier "create " has already failed.
  # Like editable_cells, a note is writable only exactly where its author placed
  # a button; everything else stays read-only.

  Background:
    Given the Heddle app is running
    And the store is empty

  Scenario: Viewing a button does not perform its actions
    Given a note titled "Tools" with body:
      """
      {% button "Make note" %}
        create "Generated" body="hello"
      {% endbutton %}
      """
    When I view the note "Tools"
    Then no note titled "Generated" exists

  Scenario: Clicking a button runs its create action
    Given a note titled "Tools" with body:
      """
      {% button "Make note" %}
        create "Generated" body="hello"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Make note"
    Then a note titled "Generated" exists
    And the strand "Generated" has body "hello"

  Scenario: A set action writes a field of an existing strand
    Given a note titled "Coffee Brewing" with body "old"
    And a note titled "Tools" with body:
      """
      {% button "Overwrite" %}
        set "Coffee Brewing" body="new"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Overwrite"
    Then the strand "Coffee Brewing" has body "new"

  Scenario: Actions run in the order they are written
    Given a note titled "Log" with body "start"
    And a note titled "Tools" with body:
      """
      {% button "Run" %}
        set "Log" body="first"
        set "Log" body="second"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Run"
    Then the strand "Log" has body "second"

  Scenario: Argument values are evaluated when the button is pressed
    # The title is read from another strand at click time, not at render time.
    Given a note titled "Source" with body "current name"
    And a note titled "Tools" with body:
      """
      {% button "Make" %}
        create {{ strands["Source"].body }} body="x"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I change the strand "Source" body to "updated name"
    And I click the button "Make"
    Then a note titled "updated name" exists
    And no note titled "current name" exists

  Scenario: A button's actions are a single all-or-nothing transaction
    # The create fails (a blank title is invalid), so the later set must not run
    # and the existing draft is preserved.
    Given a note titled "Draft" with body "keep me"
    And a note titled "Tools" with body:
      """
      {% button "File it" %}
        create "" body="x"
        set "Draft" body=""
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "File it"
    Then the button reports an error
    And the strand "Draft" has body "keep me"

  Scenario: Creating a note whose title already exists gets a distinct title
    # Titles are unique (strand_common.feature). A create collision neither
    # overwrites nor fails; the new strand is given a distinct, derived title.
    Given a note titled "Inbox Item" with body "first"
    And a note titled "Tools" with body:
      """
      {% button "Add" %}
        create "Inbox Item" body="second"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Add"
    Then the strand "Inbox Item" has body "first"
    And a second strand with a title derived from "Inbox Item" has body "second"

  Scenario: A set action writes several values to a multi-valued field with a list literal
    # A "[...]" list literal sets a multi-valued field. Items are comma-separated
    # barewords (or quoted strings); the brackets make "list" a property of the
    # syntax, so a multi-valued write is never confused with a single string and
    # clean tokens need no per-item quoting.
    Given the property "moods" is defined as multi-select with options "bright, bold, sweet"
    And a note titled "Coffee Brewing" with body "x"
    And a note titled "Tools" with body:
      """
      {% button "Tag moods" %}
        set "Coffee Brewing" moods=[bright, sweet]
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Tag moods"
    Then the strand "Coffee Brewing" has property "moods" containing "bright" and "sweet"

  Scenario: A bareword argument value is a literal string
    # An unquoted value is a literal, exactly like a quoted one. "{{ }}" is the
    # only marker for an expression, so "body=hello" stores the text "hello", not
    # the value of a variable named hello.
    Given a note titled "Tools" with body:
      """
      {% button "Make" %}
        create "Generated" body=hello
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Make"
    Then the strand "Generated" has body "hello"

  Scenario: A list item keeps internal whitespace without being quoted
    # Comma is the only separator inside "[...]", so whitespace belongs to an item
    # rather than delimiting it: "[New York, NY]" is two items, not three, and
    # needs no quotes. (A comma inside a value is the only thing that forces
    # quoting: "[\"a,b\", c]" is two items.)
    Given the property "places" is defined as multi-select with options "New York, NY, LA"
    And a note titled "Coffee Brewing" with body "x"
    And a note titled "Tools" with body:
      """
      {% button "Tag places" %}
        set "Coffee Brewing" places=[New York, NY]
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Tag places"
    Then the strand "Coffee Brewing" has property "places" containing "New York" and "NY"
