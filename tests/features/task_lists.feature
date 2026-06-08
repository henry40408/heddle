Feature: Task lists
  As a user who jots to-dos as I write
  I want a plain "- [ ] ..." line to be a real, tickable task
  So that I can create a task by typing one line and still gather tasks across my web

  # A task is a Markdown task-list line ("- [ ] text" open, "- [x] text" done)
  # inside any note's body -- not a separate strand and not a structured
  # property. Creating a task costs one line. In the task's own note, ticking
  # the checkbox writes "[x]" straight back into that line. Because that is a
  # body change, it counts as an edit and bumps the source note's updated-at
  # (strand_common.feature) -- even when the tick happens from an aggregated
  # view, where only the source note's timestamp moves, not the dashboard's.
  # The engine indexes
  # every task line, so "task:open" / "task:done" (structured_query.feature) can
  # gather tasks across notes, and a dynamic embed (dynamic_transclusion.feature)
  # can list them on a dashboard. Ticking a task in such an aggregated view is
  # the read-only carve-out: only the single checkbox writes back -- to the one
  # source line it came from -- while the surrounding transcluded text stays
  # read-only. Each indexed task remembers its source note and position so the
  # right line is updated and "go to source" works.

  Background:
    Given the Heddle app is running
    And the store is empty

  Scenario: A Markdown task line renders as a checkbox
    Given a note titled "Groceries" with body:
      """
      - [ ] Buy beans
      - [x] Buy milk
      """
    When I view the note "Groceries"
    Then the task "Buy beans" shows an unchecked checkbox
    And the task "Buy milk" shows a checked checkbox

  Scenario: Ticking a task in its own note writes back to the body
    Given a note titled "Groceries" with body "- [ ] Buy beans"
    And I am viewing the note "Groceries"
    When I tick the task "Buy beans"
    Then the body of "Groceries" contains "- [x] Buy beans"

  Scenario: Unticking a task in its own note writes back to the body
    Given a note titled "Groceries" with body "- [x] Buy beans"
    And I am viewing the note "Groceries"
    When I untick the task "Buy beans"
    Then the body of "Groceries" contains "- [ ] Buy beans"

  Scenario: Ticking a task in its own note bumps the note's updated-at
    Given a note titled "Groceries" with body "- [ ] Buy beans"
    And I am viewing the note "Groceries"
    When I tick the task "Buy beans"
    Then the updated-at timestamp of "Groceries" is newer than before

  Scenario: task:open gathers unfinished tasks across notes
    Given a note titled "Groceries" with body:
      """
      - [ ] Buy beans
      - [x] Buy milk
      """
    And a note titled "Errands" with body "- [ ] Mail package"
    When I run the query "task:open"
    Then the task results include "Buy beans"
    And the task results include "Mail package"
    And the task results do not include "Buy milk"

  Scenario: task:done gathers finished tasks
    Given a note titled "Groceries" with body:
      """
      - [ ] Buy beans
      - [x] Buy milk
      """
    When I run the query "task:done"
    Then the task results include "Buy milk"
    And the task results do not include "Buy beans"

  Scenario: Tasks can be filtered by their source note's tag
    Given a note titled "Coffee Plan" with body "- [ ] Order filters" tagged "coffee"
    And a note titled "Garden Plan" with body "- [ ] Water seedlings" tagged "garden"
    When I run the query "task:open tag:coffee"
    Then the task results include "Order filters"
    And the task results do not include "Water seedlings"

  Scenario: A dashboard embeds open tasks gathered from the whole web
    Given a note titled "Groceries" with body "- [ ] Buy beans"
    And a note titled "Errands" with body "- [ ] Mail package"
    And a note titled "Today" with body "{{{ task:open }}}"
    When I view the note "Today"
    Then the rendered output lists "Buy beans"
    And the rendered output lists "Mail package"
    And the task "Buy beans" offers a "go to source" action that opens the note "Groceries"

  Scenario: Ticking a task in an aggregated view writes back to its source line
    Given a note titled "Groceries" with body "- [ ] Buy beans"
    And a note titled "Today" with body "{{{ task:open }}}"
    And I am viewing the note "Today"
    When I tick the task "Buy beans" in the aggregated list
    Then the body of "Groceries" contains "- [x] Buy beans"
    And re-running the query "task:open" does not include "Buy beans"

  Scenario: An aggregated task is read-only apart from its checkbox
    Given a note titled "Groceries" with body "- [ ] Buy beans"
    And a note titled "Today" with body "{{{ task:open }}}"
    When I view the note "Today"
    Then the aggregated task "Buy beans" offers no inline text editing
    And only its checkbox is interactive

  Scenario: Ticking one aggregated task leaves sibling tasks in the same note untouched
    Given a note titled "Groceries" with body:
      """
      - [ ] Buy beans
      - [ ] Buy milk
      """
    And a note titled "Today" with body "{{{ task:open }}}"
    And I am viewing the note "Today"
    When I tick the task "Buy beans" in the aggregated list
    Then the body of "Groceries" contains "- [x] Buy beans"
    And the body of "Groceries" contains "- [ ] Buy milk"

  Scenario: Ticking an aggregated task bumps only the source note's updated-at
    Given a note titled "Groceries" with body "- [ ] Buy beans"
    And a note titled "Today" with body "{{{ task:open }}}"
    And I am viewing the note "Today"
    When I tick the task "Buy beans" in the aggregated list
    Then the updated-at timestamp of "Groceries" is newer than before
    And the updated-at timestamp of "Today" is unchanged
