Feature: activity log

  In order to track who operates on what task
  As a user of Singleshot
  I want each task to have an activity log

  Scenario: creating a new task
    Given a newly created task "expenses"
    Then activity log should show creator created "expenses"

  Scenario: creating and claiming a new task
    Given a newly created task "expenses" assigned to creator
    Then activity log should show creator created "expenses"
    And activity log should show creator owns "expenses"

  Scenario: creating and delegating a new task
    Given a newly created task "expenses" assigned to owner
    Then activity log should show creator created "expenses"
    And activity log should show owner owns "expenses"

  Scenario: owner claiming task
    Given a newly created task "expenses"
    And potential owners alice, bob for "expenses"
    When alice claims task "expenses"
    Then activity log should show alice owns "expenses"

  Scenario: owner delegating task
    Given a newly created task "expenses"
    And potential owners alice, bob for "expenses"
    And alice claims task "expenses"
    When alice delegates task "expenses" to bob
    Then activity log should show alice delegated "expenses"
    Then activity log should show bob owns "expenses"

  Scenario: supervisor delegating task
    Given a newly created task "expenses"
    And potential owners alice, bob for "expenses"
    And supervisor chuck for "expenses"
    When chuck delegates task "expenses" to alice
    Then activity log should show chuck delegated "expenses"
    Then activity log should show alice owns "expenses"

  Scenario: owner releases task
    Given a newly created task "expenses"
    And owner alice for "expenses"
    When alice releases task "expenses"
    Then activity log should show alice released "expenses"

  Scenario: supervisor suspending task
    Given a newly created task "expenses"
    And supervisor chuck for "expenses"
    When chuck suspends task "expenses"
    Then activity log should show chuck suspended "expenses"

  Scenario: supervisor resuming task
    Given a newly created task "expenses"
    And supervisor chuck for "expenses"
    And chuck suspends task "expenses"
    When chuck resumes task "expenses"
    Then activity log should show chuck resumed "expenses"

  Scenario: supervisor cancelling task
    Given a newly created task "expenses"
    And supervisor chuck for "expenses"
    When chuck cancels task "expenses"
    Then activity log should show chuck cancelled "expenses"

  Scenario: owner cancelling task
    Given a newly created task "expenses"
    And owner alice for "expenses"
    When alice completes task "expenses"
    Then activity log should show alice completed "expenses"

  Scenario: supervisor modifying task
    Given a newly created task "expenses"
    And supervisor chuck for "expenses"
    When chuck modifies priority of task "expenses" to 5
    Then activity log should show chuck modified "expenses"
