Feature: The delete action verb
  As a user who builds small tools inside my notes
  I want a button that can remove a strand
  So that I can file-and-clear -- archive a draft, clear an inbox item -- without opening it

  # "delete" is a third action verb alongside "create " and "set"
  # (action_buttons.feature). It obeys every rule that feature already pins:
  #   - It runs ONLY on an explicit click; merely viewing a button that contains
  #     a delete never removes anything (viewing stays safe and idempotent).
  #   - A button's verbs run in written order as a single all-or-nothing
  #     transaction; if any verb fails, none apply -- so a delete is rolled back
  #     when a later verb fails.
  #
  # delete names its target the way "set" does -- by title, "delete "Title"" --
  # so there is no implicit "current strand". The title may be a "{{ ... }}"
  # interpolation, evaluated at click time. A title resolves to any strand
  # (a note or a blob; strand_common.feature), so the same verb removes either.
  #
  # Deleting a strand that does not exist is a no-op that SUCCEEDS, not an error.
  # delete is therefore idempotent: clicking twice, or deleting an
  # already-gone target, never fails the transaction.
  #
  # Deletion is NOT blocked by inbound references. If a deleted strand was
  # transcluded with "![[Title]]", its embedders fall back to the existing
  # "missing source" placeholder (transclusion.feature, blob_transclusion.feature)
  # -- delete reuses that behaviour rather than guarding against it.
  #
  # delete is the one irreversible verb (create collides to a derived title, set
  # is covered by transaction rollback). It carries NO built-in confirmation:
  # the explicit click is the gate. A pre-delete prompt, if ever wanted, is a
  # UI-layer affordance and out of scope for this behaviour spec.

  Background:
    Given the Heddle app is running
    And the store is empty

  Scenario: Viewing a delete button does not delete anything
    Given a note titled "Stale" with body "remove me"
    And a note titled "Tools" with body:
      """
      {% button "Clear" %}
        delete "Stale"
      {% endbutton %}
      """
    When I view the note "Tools"
    Then a note titled "Stale" exists

  Scenario: Clicking a delete button removes the named strand
    Given a note titled "Stale" with body "remove me"
    And a note titled "Tools" with body:
      """
      {% button "Clear" %}
        delete "Stale"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Clear"
    Then no note titled "Stale" exists

  Scenario: The delete target title is evaluated when the button is pressed
    # The title is read from another strand at click time, not at render time.
    Given a note titled "Old Name" with body "x"
    And a note titled "Pointer" with body "Old Name"
    And a note titled "Tools" with body:
      """
      {% button "Drop" %}
        delete {{ strands["Pointer"].body }}
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Drop"
    Then no note titled "Old Name" exists

  Scenario: Deleting a strand that does not exist is a no-op, not an error
    Given a note titled "Tools" with body:
      """
      {% button "Clear" %}
        delete "Ghost"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Clear"
    Then the button reports no error

  Scenario: Delete is idempotent across repeated clicks
    Given a note titled "Once" with body "x"
    And a note titled "Tools" with body:
      """
      {% button "Clear" %}
        delete "Once"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Clear"
    And I click the button "Clear"
    Then no note titled "Once" exists
    And the button reports no error

  Scenario: A delete is rolled back when a later verb in the same button fails
    # The create fails (a blank title is invalid), so the earlier delete must not
    # be applied and the target strand is preserved.
    Given a note titled "Keep" with body "still here"
    And a note titled "Tools" with body:
      """
      {% button "File it" %}
        delete "Keep"
        create "" body="x"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "File it"
    Then the button reports an error
    And a note titled "Keep" exists
    And the strand "Keep" has body "still here"

  Scenario: Verbs including delete run in the order they are written
    # File-and-clear: copy the draft into an inbox note, then drop the draft.
    Given a note titled "QuickNote" with body "buy filters"
    And a note titled "Tools" with body:
      """
      {% button "File it" %}
        create "Inbox Item" body={{ strands["QuickNote"].body }}
        delete "QuickNote"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "File it"
    Then a note titled "Inbox Item" exists
    And the strand "Inbox Item" has body "buy filters"
    And no note titled "QuickNote" exists

  Scenario: Deleting a transcluded source leaves embedders with the generic placeholder
    Given a note titled "Brew Params" with body "Ratio 1:16."
    And a note titled "Coffee Brewing" with body "![[Brew Params]]"
    And a note titled "Tools" with body:
      """
      {% button "Drop source" %}
        delete "Brew Params"
      {% endbutton %}
      """
    And I am viewing the note "Tools"
    When I click the button "Drop source"
    And I view the note "Coffee Brewing"
    Then the embed shows a "missing source: Brew Params" placeholder
