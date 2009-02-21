Feature: activity log

  In order to know who operated on what task
  As a user of Singleshot
  I want an activity log that records changes to the tasks


  Scenario: log shows owner creating task
    Given the task "expenses" created by scott
    Then the activity log shows the entries
      """
      scott created expenses
      """

  Scenario: log shows owner creating and claiming task
    Given the task "expenses" created by scott and assigned to scott
    Then the activity log shows the entries
      """
      scott created expenses
      scott owns expenses
      """

  Scenario: log shows owner creating and delegating task
    Given the task "expenses" created by scott and assigned to alice
    Then the activity log shows the entries
      """
      scott created expenses
      alice owns expenses
      """

  Scenario: log shows potential owner claiming task
    Given the task "expenses" created by scott
    And alice is potential owner of task "expenses"
    And bob is potential owner of task "expenses"
    When alice claims the task "expenses"
    Then the activity log shows the entries
      """
      scott created expenses
      alice owns expenses
      """

  Scenario: log shows owner delegating task
    Given the task "expenses" created by scott
    And alice is owner of task "expenses"
    And bob is potential owner of task "expenses"
    When alice delegates the task "expenses" to bob
    Then the activity log shows the entries
      """
      scott created expenses
      alice delegated expenses
      bob owns expenses
      """

  Scenario: log shows supervisor delegating task
    Given the task "expenses" created by scott
    And alice is owner of task "expenses"
    And bob is potential owner of task "expenses"
    When scott delegates the task "expenses" to bob
    Then the activity log shows the entries
      """
      scott created expenses
      scott delegated expenses
      bob owns expenses
      """

  Scenario: log shows owner released task
    Given the task "expenses" created by scott
    And alice is owner of task "expenses"
    When alice releases the task "expenses"
    Then the activity log shows the entries
      """
      scott created expenses
      alice released expenses
      """

  Scenario: log shows supervisor modified task
    Given the task "expenses" created by scott
    When scott modifies the priority of task "expenses" to 5
    Then the activity log shows the entries
      """
      scott created expenses
      scott modified expenses
      """

  Scenario: log shows supervisor suspended task
    Given the task "expenses" created by scott
    When scott suspends the task "expenses"
    Then the activity log shows the entries
      """
      scott created expenses
      scott suspended expenses
      """

  Scenario: log shows supervisor resumed task
    Given the task "expenses" created by scott
    And scott suspends the task "expenses"
    When scott resumes the task "expenses"
    Then the activity log shows the entries
      """
      scott created expenses
      scott suspended expenses
      scott resumed expenses
      """

  Scenario: log shows supervisor cancelled task
    Given the task "expenses" created by scott
    When scott cancels the task "expenses"
    Then the activity log shows the entries
      """
      scott created expenses
      scott cancelled expenses
      """

  Scenario: log shows owner completed task
    Given the task "expenses" created by scott
    And alice is owner of task "expenses"
    When alice completes the task "expenses"
    Then the activity log shows the entries
      """
      scott created expenses
      alice completed expenses
      """
