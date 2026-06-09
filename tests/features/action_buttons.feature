Feature: Action buttons
  As a user who builds small tools inside my notes
  I want a button in a template that performs a declared set of writes
  So that I can act on my web -- capture, file, update -- without opening each strand by hand

  # Templates render read-only by default (transclusion.feature,
  # dynamic_transclusion.feature), with one narrow exception for editable
  # property cells (editable_cells.feature). An action button is the one place a
  # template may *write*. It stays deliberately bounded:
  #   - A fixed, small verb set -- "create" and "set" -- listed in order. The
  #     list is NOT control flow: no loops, no conditionals. Argument values come
  #     from ordinary "{{ ... }}" interpolation, evaluated when the button is
  #     pressed (so they see the current state, not the render-time state).
  #   - Writes happen ONLY on an explicit user click. Merely viewing a note that
  #     contains a button never mutates anything -- viewing stays safe and
  #     idempotent, like every other rendered view.
  #   - A button's actions run as a single all-or-nothing transaction. If any
  #     action fails, none are applied, so a later "set"/clear can never destroy
  #     data after an earlier "create" has already failed.
  # Like editable_cells, a note is writable only exactly where its author placed
  # a button; everything else stays read-only.

  Background:
    Given the Heddle app is running
    And the store is empty

  Scenario: Viewing a button does not perform its actions
    Given a note titled "Tools" with body:
      """
      {% button "Make note" %}
        create note title="Generated" body="hello"
      {% endbutton %}
      """
    When I view the note "Tools"
    Then no note titled "Generated" exists

  Scenario: Clicking a button runs its create action
    Given a note titled "Tools" with body:
      """
      {% button "Make note" %}
        create note title="Generated" body="hello"
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
        set "Coffee Brewing".body = "new"
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
        set "Log".body = "first"
        set "Log".body = "second"
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
        create note title={{ "Source".body }} body="x"
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
        create note title="" body="x"
        set "Draft".body = ""
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
        create note title="Inbox Item" body="second"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Add"
    Then the strand "Inbox Item" has body "first"
    And a second strand with a title derived from "Inbox Item" has body "second"
