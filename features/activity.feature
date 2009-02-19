Feature: activity log

  As a user of Singleshot
  I want to see activities related to a task
  So I can track who did what with the task

  Scenario: creating a new task
    Given a newly created task
    Then activity log should show creator created task

  Scenario: creating and claiming a new task
    Given a newly created task assigned to creator
    Then activity log should show creator created task
    And activity log should show creator owns task

  Scenario: creating and delegating a new task
    Given a newly created task assigned to owner
    Then activity log should show creator created task
    And activity log should show owner owns task

  Scenario: owner claiming task
    Given a newly created task
    And potential owners alice, bob
    When alice claims task
    Then activity log should show alice owns task

  Scenario: owner delegating task
    Given a newly created task
    And potential owners alice, bob
    And alice claims task
    When alice delegates task to bob
    Then activity log should show alice delegated task
    Then activity log should show bob owns task

  Scenario: supervisor delegating task
    Given a newly created task
    And potential owners alice, bob
    And supervisor chuck
    When chuck delegates task to alice
    Then activity log should show chuck delegated task
    Then activity log should show alice owns task

  Scenario: owner releases task
    Given a newly created task
    And owner alice
    When alice releases task
    Then activity log should show alice released task

  Scenario: supervisor suspending task
    Given a newly created task
    And supervisor chuck
    When chuck suspends task
    Then activity log should show chuck suspended task

  Scenario: supervisor resuming task
    Given a newly created task
    And supervisor chuck
    And chuck suspends task
    When chuck resumes task
    Then activity log should show chuck resumed task

  Scenario: supervisor cancelling task
    Given a newly created task
    And supervisor chuck
    When chuck cancels task
    Then activity log should show chuck cancelled task

  Scenario: owner cancelling task
    Given a newly created task
    And owner alice
    When alice completes task
    Then activity log should show alice completed task

  Scenario: supervisor modifying task
    Given a newly created task
    And supervisor chuck
    When chuck modifies task title
    Then activity log should show chuck modified task
