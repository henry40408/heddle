Feature: Capping a dynamic query with limit
  As a user assembling a dashboard from a query
  I want to keep only the first N matched strands
  So that a "latest N" or "top N" view stays short instead of listing everything

  # "sort" (query_sort.feature) fixes the ORDER of matches; "limit" caps the
  # COUNT. Together they express "latest/top N": order with sort, then truncate
  # with limit. Like sort, "limit" is a PIPELINE operator that lives INSIDE the
  # query string, not an attribute on the query tag, so the whole pipeline is
  # expressed in one place (the query AST, structured_query.feature) and
  # "{% query %}" stays a thin wrapper. So:
  #     {% query "tag:coffee sort:-rating limit:2" %}   -- order by rating desc, keep the top 2
  #
  # PIPELINE STAGES are FIXED, not left-to-right: a query is filter -> sort ->
  # limit regardless of where each operator sits in the string. "limit" always
  # applies AFTER "sort" (it truncates the ordered result), so
  #     {% query "limit:2 tag:coffee sort:-rating" %}
  # and
  #     {% query "tag:coffee sort:-rating limit:2" %}
  # render the same two strands. Ordering and capping are each declared once in
  # the AST, not re-sequenced by token position.
  #
  # "limit" does NOT require "sort": a bare "{% query "tag:coffee limit:2" %}" is
  # legal but, like a bare query (dynamic_transclusion.feature), the order -- and
  # therefore WHICH two strands survive -- is unspecified. Every scenario below
  # that asserts identity pairs "limit" with "sort" so the outcome is total.
  #
  # Boundaries and bad input mirror sort's "friendly placeholder, page does not
  # crash" contract:
  #   - N larger than the result count returns all matches (no padding, no error).
  #   - "limit:0" is a legal count of zero -> the empty-result placeholder, NOT an
  #     error (0 is a valid integer and may arrive via interpolation "limit:{{ n }}").
  #   - "limit:" (no value) reports "missing value for limit" (mirrors "sort:").
  #   - "limit:abc" (not an integer) reports "limit must be a whole number".
  #   - "limit:-3" (negative) is invalid input -> placeholder. The leading "-" is
  #     NOT borrowed from sort's descending marker: truncation has no "reverse"
  #     meaning, and a tail view is already "sort:-key limit:N".

  Background:
    Given the Heddle app is running
    And the store is empty
    And the property "rating" is defined as number
    And the following notes exist:
      | title          | body | tags   |
      | Coffee Brewing | x    | coffee |
      | Aeropress Test | x    | coffee |
      | Pour Over      | x    | coffee |
      | Cold Brew      | x    | coffee |
      | Flat White     | x    | coffee |
    And the note "Coffee Brewing" has property "rating" set to "2"
    And the note "Aeropress Test" has property "rating" set to "10"
    And the note "Pour Over" has property "rating" set to "5"
    And the note "Cold Brew" has property "rating" set to "8"
    And the note "Flat White" has property "rating" set to "1"

  Scenario: Limit keeps the first N of the ordered result
    Given a note titled "Top Coffees" with body "{% query "tag:coffee sort:-rating limit:2" %}"
    When I view the note "Top Coffees"
    Then the rendered list order is "Aeropress Test", "Cold Brew"

  Scenario: A limit larger than the result count returns every match
    Given a note titled "All Coffees" with body "{% query "tag:coffee sort:-rating limit:10" %}"
    When I view the note "All Coffees"
    Then the rendered list order is "Aeropress Test", "Cold Brew", "Pour Over", "Coffee Brewing", "Flat White"
    And the page does not show an error

  Scenario: A limit of zero shows the empty-state, not an error
    Given a note titled "No Coffees" with body "{% query "tag:coffee sort:-rating limit:0" %}"
    When I view the note "No Coffees"
    Then the rendered output shows an empty-result placeholder
    And the page does not show an error

  Scenario: Limit applies after sort regardless of its position in the query
    Given a note titled "Top Front" with body "{% query "limit:2 tag:coffee sort:-rating" %}"
    And a note titled "Top Back" with body "{% query "tag:coffee sort:-rating limit:2" %}"
    When I view the note "Top Front"
    Then the rendered list order is "Aeropress Test", "Cold Brew"
    When I view the note "Top Back"
    Then the rendered list order is "Aeropress Test", "Cold Brew"

  Scenario: Limit is preserved when matches render through a template
    Given a note titled "Row" with body "{{ it.title }} ({{ it.rating }})"
    And a note titled "Top Board" with body "{% query "tag:coffee sort:-rating limit:2" template="Row" %}"
    When I view the note "Top Board"
    Then the rendered output contains "Aeropress Test (10)" before "Cold Brew (8)"
    And the rendered output does not contain "Pour Over (5)"

  Scenario: Limiting an empty result shows the empty-state, not an error
    Given a note titled "Empty Top" with body "{% query "tag:nonexistent sort:title limit:3" %}"
    When I view the note "Empty Top"
    Then the rendered output shows an empty-result placeholder
    And the page does not show an error

  Scenario: Limit with no value reports a friendly error
    Given a note titled "Broken Limit" with body "{% query "tag:coffee sort:-rating limit:" %}"
    When I view the note "Broken Limit"
    Then the embed shows a "missing value for limit" placeholder
    And the page does not hang

  Scenario: A non-integer limit reports a friendly error
    Given a note titled "Wordy Limit" with body "{% query "tag:coffee sort:-rating limit:abc" %}"
    When I view the note "Wordy Limit"
    Then the embed shows a "limit must be a whole number" placeholder
    And the page does not hang

  Scenario: A negative limit reports a friendly error
    Given a note titled "Negative Limit" with body "{% query "tag:coffee sort:-rating limit:-3" %}"
    When I view the note "Negative Limit"
    Then the embed shows a "limit must be a whole number" placeholder
    And the page does not hang
