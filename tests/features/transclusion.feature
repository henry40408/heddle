Feature: Note-level transclusion
  As a user who reuses content across notes
  I want to embed one note inside another with ![[Title]]
  So that content lives in one place but appears wherever I need it

  Background:
    Given the Heddle app is running
    And the note store is empty

  Scenario: Transclude renders the source content inline
    Given a note titled "Brew Params" with body "Ratio 1:16, water 92C, bloom 30s."
    And a note titled "Coffee Brewing" with body:
      """
      Pour-over depends on water temperature.

      ![[Brew Params]]

      Try lighter roast next time.
      """
    When I view the note "Coffee Brewing"
    Then the rendered output contains "Ratio 1:16, water 92C, bloom 30s."
    And the transcluded content is marked as coming from "Brew Params"

  Scenario: Editing the source updates every embedding note
    Given a note titled "Brew Params" with body "Ratio 1:16."
    And a note titled "Coffee Brewing" with body "![[Brew Params]]"
    And a note titled "Cafe Log" with body "![[Brew Params]]"
    When I edit the note "Brew Params" and set its body to "Ratio 1:15."
    Then viewing the note "Coffee Brewing" contains "Ratio 1:15."
    And viewing the note "Cafe Log" contains "Ratio 1:15."

  Scenario: Transcluded content is read-only
    Given a note titled "Brew Params" with body "Ratio 1:16."
    And a note titled "Coffee Brewing" with body "![[Brew Params]]"
    When I view the note "Coffee Brewing"
    Then the transcluded "Brew Params" content offers no inline editing
    And it offers a "go to source" action that opens the note "Brew Params"

  Scenario: Transcluding an unresolved title shows a generic placeholder
    Given a note titled "Coffee Brewing" with body "![[Ghost Note]]"
    When I view the note "Coffee Brewing"
    Then the embed shows a "missing source: Ghost Note" placeholder
    And the placeholder does not claim whether the target was a note or an attachment

  Scenario: Deleting a transcluded source shows a generic placeholder in embedders
    Given a note titled "Brew Params" with body "Ratio 1:16."
    And a note titled "Coffee Brewing" with body "![[Brew Params]]"
    When I delete the note "Brew Params"
    And I view the note "Coffee Brewing"
    Then the embed shows a "missing source: Brew Params" placeholder

  Scenario: A note appears as a backlink of the note it transcludes
    Given a note titled "Brew Params" with body "Ratio 1:16."
    And a note titled "Coffee Brewing" with body "![[Brew Params]]"
    When I view the note "Brew Params"
    Then the backlinks panel lists "Coffee Brewing"

  Scenario: Direct self-transclusion is prevented
    When I create a note titled "Loop" with body "![[Loop]]"
    And I view the note "Loop"
    Then the embed shows a "cannot transclude itself" placeholder
    And the page does not hang

  Scenario: Indirect transclusion cycles are prevented
    Given a note titled "A" with body "start ![[B]]"
    And a note titled "B" with body "middle ![[A]]"
    When I view the note "A"
    Then the rendered output contains "start"
    And the rendered output contains "middle"
    And the second occurrence of "A" in the cycle shows a "cycle detected" placeholder
    And the page does not hang

  # Transclusion addresses its source BY TITLE, so renaming a source could orphan
  # every "![[Title]]" that embeds it. Wiki links already guarantee survival across
  # a rename (wiki_links_and_backlinks.feature); transclusion must match.
  # OPEN DECISION (mechanism only -- recorded here, not yet chosen):
  #   (A) relink: rewrite "![[Old]]" to "![[New]]" in every embedder's body, so the
  #       raw body shows the new title in edit mode; or
  #   (B) id-addressed references: "![[Title]]" is display sugar over a stable id,
  #       so the raw body is never touched and nothing needs rewriting.
  # The scenario below asserts only the user-visible guarantee (the embed stays
  # resolved and follows the new title), which holds under either (A) or (B); the
  # raw-body behaviour is deliberately left unspecified until the choice is made.

  Scenario: Renaming a transcluded source keeps every embedding resolved
    Given a note titled "Brew Params" with body "Ratio 1:16."
    And a note titled "Coffee Brewing" with body "![[Brew Params]]"
    And a note titled "Cafe Log" with body "![[Brew Params]]"
    When I rename the note "Brew Params" to "Pour-over Params"
    Then viewing the note "Coffee Brewing" contains "Ratio 1:16."
    And viewing the note "Cafe Log" contains "Ratio 1:16."
    And the embed in "Coffee Brewing" shows no "missing source" placeholder
    And the transcluded content is marked as coming from "Pour-over Params"
