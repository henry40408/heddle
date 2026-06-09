Feature: Relinking references when a strand is renamed
  As a user who renames notes and blobs as my thinking changes
  I want every reference to follow the rename automatically
  So that a rename never orphans a link, an embed, or a template view

  # Several reference families address their target BY TITLE: "[[Title]]" wiki
  # links (wiki_links_and_backlinks.feature), "![[Title]]" static transclusion
  # and blob embeds (transclusion.feature, blob_transclusion.feature), and the
  # "template="Name"" of a dynamic query (dynamic_transclusion.feature). Renaming
  # a target could orphan all of them. The per-feature rename scenarios assert the
  # user-visible guarantee (the reference stays resolved and follows the new
  # title); THIS feature pins the MECHANISM that was left open there.
  #
  # CHOSEN MECHANISM: (A) relink by parse-then-rewrite -- NOT (B) id-addressing,
  # and NOT regex. On rename, Heddle rewrites the raw stored body of every
  # referencing strand so "![[Old]]" becomes "![[New]]" (and "[[Old]]",
  # "template="Old""). The raw body therefore shows the NEW title in edit mode.
  # This keeps the whole point of title syntax over opaque ids: a body stays
  # human-readable, hand-editable, exportable, and diff-friendly.
  #
  # It is safe because the reference grammar is small and CLOSED, so it is parsed,
  # not pattern-matched: a literal "![[Old]]" sitting inside a code block is not a
  # reference (it creates no backlink) and is left untouched -- a regex could not
  # tell the difference. Rewriting is by RESOLVED IDENTITY: a reference is
  # rewritten because it resolves to the renamed strand, not because its text
  # matched a string. The backlinks index drives it, so only actual referrers are
  # touched, never a full-store scan.
  #
  # Relink is a system consistency rewrite, not a user edit: it does NOT bump a
  # referrer's updated-at (only the renamed strand's own title/timestamp move),
  # the same carve-out task_lists.feature makes for an aggregated tick.
  #
  # Forward-looking constraint: the grammar must stay free of reference-vs-literal
  # ambiguity. A future search operator like title:"..." would reintroduce the
  # ambiguity TW5's wikitext relinker struggles with, and would have to be parsed
  # with the same care (or relink would misfire).

  Background:
    Given the Heddle app is running
    And the store is empty

  Scenario: Renaming a source rewrites the static embed in the referrer's raw body
    Given a note titled "Brew Params" with body "Ratio 1:16."
    And a note titled "Coffee Brewing" with body "See ![[Brew Params]] for details."
    When I rename the note "Brew Params" to "Pour-over Params"
    Then the body of "Coffee Brewing" contains "![[Pour-over Params]]"
    And the body of "Coffee Brewing" does not contain "![[Brew Params]]"

  Scenario: Renaming a target rewrites a wiki link in the referrer's raw body
    Given a note titled "Pour-over Notes" with body "details"
    And a note titled "Morning Ritual" with body "I follow [[Pour-over Notes]] daily."
    When I rename the note "Pour-over Notes" to "Hand Pour"
    Then the body of "Morning Ritual" contains "[[Hand Pour]]"
    And the body of "Morning Ritual" does not contain "[[Pour-over Notes]]"

  Scenario: Renaming a blob rewrites the embeds that point to it
    Given an uploaded image "coffee-setup.png"
    And a note titled "Gear" with body "My rig: ![[coffee-setup.png]]"
    When I rename the blob "coffee-setup.png" to "rig.png"
    Then the body of "Gear" contains "![[rig.png]]"
    And the body of "Gear" does not contain "![[coffee-setup.png]]"

  Scenario: Renaming a template strand rewrites the template name in the query
    Given a note titled "Row" with body "{{ it.title }}"
    And a note titled "Coffee Cards" with body "{% query "tag:coffee" template="Row" %}"
    When I rename the note "Row" to "Card"
    Then the body of "Coffee Cards" contains "template=\"Card\""
    And the body of "Coffee Cards" does not contain "template=\"Row\""

  Scenario: A literal reference inside a code block is not rewritten
    # The fenced block is display text, not a reference -- it creates no backlink,
    # so a parse-then-rewrite leaves it alone where a regex would corrupt it.
    Given a note titled "Brew Params" with body "Ratio 1:16."
    And a note titled "Docs" with body:
      """
      Real embed: ![[Brew Params]]

      To embed it, write this literally:

      ```
      ![[Brew Params]]
      ```
      """
    When I rename the note "Brew Params" to "Pour-over Params"
    Then the body of "Docs" contains "Real embed: ![[Pour-over Params]]"
    And the body of "Docs" still contains the literal "![[Brew Params]]" inside the code block

  Scenario: Relinking a referrer does not bump its updated-at
    Given a note titled "Brew Params" with body "Ratio 1:16."
    And a note titled "Coffee Brewing" with body "![[Brew Params]]"
    And I am viewing the note "Coffee Brewing"
    When I rename the note "Brew Params" to "Pour-over Params"
    Then the body of "Coffee Brewing" contains "![[Pour-over Params]]"
    And the updated-at timestamp of "Coffee Brewing" is unchanged
