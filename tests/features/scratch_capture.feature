Feature: Scratch capture with autosave
  As a user who jots quick thoughts
  I want a draft buffer I can type into and file with one click
  So that I can capture without ceremony and never lose an in-progress note

  # A "scratch" strand is an ordinary note (note_management.feature) used as a
  # draft buffer. Two pieces make a capture tool:
  #   - "{{ strands["Title"].body | edit: multiline, autosave }}" binds a multiline
  #     editor to a named strand's body. Unlike the deliberate save/cancel editor
  #     (editing.feature), an "autosave" binding persists by itself -- after a
  #     short idle pause, on blur, and when the page is closed -- so a draft
  #     survives a reload or a closed browser. This is a deliberate exception to
  #     editing.feature's discard-on-cancel rule, scoped to scratch buffers only.
  #   - A "{% preview %}" region re-renders as the user types, for DISPLAY ONLY.
  #     Typing never writes the store; the store changes only on autosave or on an
  #     action button (action_buttons.feature). Other views of the scratch strand
  #     do not update live while typing -- they re-resolve when next viewed.
  # The scratch strand is a normal, searchable strand. "{% capture_form
  # scratch=<title> %}" binds the name "scratch" to that strand for the form.
  # Two Heddle-provided constructs appear here: the "strands["Title"]" drop reaches
  # a named strand, and "rest" is a filter returning all array items after the
  # first (Liquid has first/last but no tail), as in "split: "\n" | rest | join".

  Background:
    Given the Heddle app is running
    And the store is empty

  Scenario: An autosave editor is prefilled from its strand
    Given a note titled "QuickNote" with body "earlier draft"
    And a note titled "Capture" with body:
      """
      {{ strands["QuickNote"].body | edit: multiline, autosave }}
      """
    When I view the note "Capture"
    Then the scratch editor is prefilled with "earlier draft"

  Scenario: Typing updates the preview without writing the store
    Given a note titled "QuickNote" with body ""
    And a note titled "Capture" with body:
      """
      {% capture_form scratch="QuickNote" %}
        {{ scratch.body | edit: multiline, autosave }}
        {% preview %}{{ scratch.body }}{% endpreview %}
      {% endcapture_form %}
      """
    And I am viewing the note "Capture"
    When I type "buy beans" into the scratch editor
    Then the preview shows "buy beans"
    And the strand "QuickNote" has body ""

  Scenario: Autosave persists the draft so it survives a reload
    Given a note titled "QuickNote" with body ""
    And a note titled "Capture" with body:
      """
      {{ strands["QuickNote"].body | edit: multiline, autosave }}
      """
    And I am viewing the note "Capture"
    When I type "buy beans" into the scratch editor
    And the editor autosaves
    Then the strand "QuickNote" has body "buy beans"
    And reopening the note "Capture" prefills the scratch editor with "buy beans"

  Scenario: Closing the page keeps the last edit
    Given a note titled "QuickNote" with body ""
    And a note titled "Capture" with body:
      """
      {{ strands["QuickNote"].body | edit: multiline, autosave }}
      """
    And I am viewing the note "Capture"
    When I type "half a thought" into the scratch editor
    And I close the page before any idle autosave fires
    Then the strand "QuickNote" has body "half a thought"

  Scenario: A scratch strand is created on first autosave if it does not exist
    Given no note titled "QuickNote" exists
    And a note titled "Capture" with body:
      """
      {{ strands["QuickNote"].body | edit: multiline, autosave }}
      """
    And I am viewing the note "Capture"
    When I type "first thought" into the scratch editor
    And the editor autosaves
    Then a note titled "QuickNote" exists
    And the strand "QuickNote" has body "first thought"

  Scenario: The scratch strand is an ordinary searchable strand
    Given a note titled "QuickNote" with body "findable draft"
    When I search for "findable"
    Then the search results include "QuickNote"

  Scenario: Quick capture files the draft and clears the buffer
    Given a note titled "QuickNote" with body ""
    And a note titled "Capture" with body:
      """
      {% capture_form scratch="QuickNote" %}
        {{ scratch.body | edit: multiline, autosave }}
        {% button "Send to inbox" %}
          create {{ scratch.body | split: "\n" | first }}
            tags=["inbox"]
            body={{ scratch.body | split: "\n" | rest | join: "\n" }}
          set scratch body=""
        {% endbutton %}
      {% endcapture_form %}
      """
    And I am viewing the note "Capture"
    When I type the following into the scratch editor:
      """
      Buy beans
      light roast, single origin
      """
    And I click the button "Send to inbox"
    Then a note titled "Buy beans" exists
    And the strand "Buy beans" has body "light roast, single origin"
    And the strand "Buy beans" has the tag "inbox"
    And the strand "QuickNote" has body ""

  Scenario: Sending an empty draft fails safely and keeps the buffer
    # The draft is empty, so the computed title is blank and "create" is invalid.
    # The all-or-nothing transaction rolls back: nothing is filed and the later
    # clear never runs, so the buffer is left as the user left it.
    Given a note titled "QuickNote" with body ""
    And a note titled "Capture" with body:
      """
      {% capture_form scratch="QuickNote" %}
        {{ scratch.body | edit: multiline, autosave }}
        {% button "Send to inbox" %}
          create {{ scratch.body | split: "\n" | first }}
            tags=["inbox"]
            body={{ scratch.body | split: "\n" | rest | join: "\n" }}
          set scratch body=""
        {% endbutton %}
      {% endcapture_form %}
      """
    And I am viewing the note "Capture"
    When I click the button "Send to inbox"
    Then the button reports an error
    And no strand is tagged "inbox"
    And the strand "QuickNote" has body ""
