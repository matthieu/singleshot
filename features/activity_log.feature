Feature: activity log

  In order to track who operates on what task
  As a user of Singleshot
  I want each task to have an activity log

  Scenario: creating a new task
    Given a newly created task "expenses"
    And I am logged in as "creator"
    Then last activity in log should be "creator created expenses"

  Scenario: creating and claiming a new task
    Given a newly created task "expenses" assigned to "creator"
    And I am logged in as "creator"
    Then activity log should include "creator created expenses"
    And last activity in log should be "creator owns expenses"

  Scenario: creating and delegating a new task
    Given a newly created task "expenses" assigned to "owner"
    And I am logged in as "creator"
    Then activity log should include "creator created expenses"
    And last activity in log should be "owner owns expenses"

  Scenario: potential owner claiming task
    Given a newly created task "expenses"
    And potential owner "alice" for "expenses"
    And potential owner "bob" for "expenses"
    When "alice" claims task "expenses"
    And I am logged in as "creator"
    Then last activity in log should be "alice owns expenses"

  Scenario: owner delegating task
    Given a newly created task "expenses"
    And potential owner "alice" for "expenses"
    And potential owner "bob" for "expenses"
    And "alice" claims task "expenses"
    When "alice" delegates task "expenses" to "bob"
    And I am logged in as "creator"
    Then activity log should include "alice delegated expenses"
    Then last activity in log should be "bob owns expenses"

  Scenario: supervisor delegating task
    Given a newly created task "expenses"
    And potential owner "alice" for "expenses"
    And potential owner "bob" for "expenses"
    And supervisor "chuck" for "expenses"
    When "chuck" delegates task "expenses" to "alice"
    And I am logged in as "creator"
    Then activity log should include "chuck delegated expenses"
    Then last activity in log should be "alice owns expenses"

  Scenario: owner releases task
    Given a newly created task "expenses"
    And owner "alice" for "expenses"
    When "alice" releases task "expenses"
    And I am logged in as "creator"
    Then last activity in log should be "alice released expenses"

  Scenario: supervisor suspending task
    Given a newly created task "expenses"
    And supervisor "chuck" for "expenses"
    When "chuck" suspends task "expenses"
    And I am logged in as "creator"
    Then last activity in log should be "chuck suspended expenses"

  Scenario: supervisor resuming task
    Given a newly created task "expenses"
    And supervisor "chuck" for "expenses"
    And "chuck" suspends task "expenses"
    When "chuck" resumes task "expenses"
    And I am logged in as "creator"
    Then last activity in log should be "chuck resumed expenses"

  Scenario: supervisor cancelling task
    Given a newly created task "expenses"
    And supervisor "chuck" for "expenses"
    When "chuck" cancels task "expenses"
    And I am logged in as "creator"
    Then last activity in log should be "chuck cancelled expenses"

  Scenario: owner completing task
    Given a newly created task "expenses"
    And owner "alice" for "expenses"
    When "alice" completes task "expenses"
    And I am logged in as "creator"
    Then last activity in log should be "alice completed expenses"

  Scenario: supervisor modifying task
    Given a newly created task "expenses"
    And supervisor "chuck" for "expenses"
    When "chuck" modifies priority of task "expenses" to 5
    And I am logged in as "creator"
    Then last activity in log should be "chuck modified expenses"
