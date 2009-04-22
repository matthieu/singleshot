Feature: activity log

  In order to know who operated on what task
  As a user of Singleshot
  I want an activity log that records changes to the tasks

  Background:
    Given the person scott
    And the person alice
    And the person bob

  Scenario: log shows owner creating task
    Given the task
      """
      title: "Expense report"
      creator: scott
      """
    Then the activity log shows the entries
      """
      scott created Expense report
      """

  Scenario: log shows owner creating and claiming task
    Given the task
      """
      title: "Expense report"
      creator: scott
      owner: scott
      """
    Then the activity log shows the entries
      """
      scott created Expense report
      scott claimed Expense report
      """

  Scenario: log shows owner creating and delegating task
    Given the task
      """
      title: "Expense report"
      creator: scott
      owner: alice
      """
    Then the activity log shows the entries
      """
      scott created Expense report
      alice claimed Expense report
      """

  Scenario: log shows potential owner claiming task
    Given the task
      """
      title: "Expense report"
      creator: scott
      potential_owners:
      - alice
      - bob
      """
    When alice claims the task "Expense report"
    Then the activity log shows the entries
      """
      scott created Expense report
      alice claimed Expense report
      """

  Scenario: log shows owner delegating task
    Given the task
      """
      title: "Expense report"
      creator: scott
      owner: alice
      potential_owners:
      - bob
      """
    When alice delegates the task "Expense report" to bob
    Then the activity log shows the entries
      """
      scott created Expense report
      alice claimed Expense report
      alice delegated Expense report
      bob claimed Expense report
      """

  Scenario: log shows supervisor delegating task
    Given the task
      """
      title: "Expense report"
      creator: scott
      supervisors: scott
      owner: alice
      potential_owners:
      - bob
      """
    When scott delegates the task "Expense report" to bob
    Then the activity log shows the entries
      """
      scott created Expense report
      alice claimed Expense report
      scott delegated Expense report
      bob claimed Expense report
      """

  Scenario: log shows owner released task
    Given the task
      """
      title: "Expense report"
      owner: alice
      """
    When alice releases the task "Expense report"
    Then the activity log shows the entries
      """
      alice claimed Expense report
      alice released Expense report
      """

  Scenario: log shows supervisor modified task
    Given the task
      """
      title: "Expense report"
      supervisors: scott
      """
    When scott modifies the priority of task "Expense report" to 3
    Then the activity log shows the entries
      """
      scott modified Expense report
      """

  Scenario: log shows supervisor suspended task
    Given the task
      """
      title: "Expense report"
      supervisors: scott
      """
    When scott suspends the task "Expense report"
    Then the activity log shows the entries
      """
      scott suspended Expense report
      """

  Scenario: log shows supervisor resumed task
    Given the task
      """
      title: "Expense report"
      supervisors: scott
      """
    And scott suspends the task "Expense report"
    When scott resumes the task "Expense report"
    Then the activity log shows the entries
      """
      scott suspended Expense report
      scott resumed Expense report
      """

  Scenario: log shows supervisor cancelled task
    Given the task
      """
      title: "Expense report"
      supervisors: scott
      """
    When scott cancels the task "Expense report"
    Then the activity log shows the entries
      """
      scott cancelled Expense report
      """

  Scenario: log shows owner completed task
    Given the task
      """
      title: "Expense report"
      creator: scott
      owner: alice
      """
    When alice completes the task "Expense report"
    Then the activity log shows the entries
      """
      scott created Expense report
      alice claimed Expense report
      alice completed Expense report
      """
