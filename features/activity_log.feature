Feature: activity log

  In order to know who operated on what task
  As a user of Singleshot
  I want an activity log that records changes to the tasks

  Background:
    Given the person scott
    And the person alice
    And the person bob

  Scenario: Creating a task shows in the log
    Given the task
      """
      title: "Expense report"
      creator: scott
      """
    Then the activity log shows the entries
      """
      scott created Expense report
      """

  Scenario: Creating and claiming a task shows in the log
    Given the task
      """
      title: "Expense report"
      creator: scott
      owner: scott
      """
    Then the activity log shows the entries
      """
      scott created Expense report
      scott is owner of Expense report
      """

  Scenario: Creating and delegating a task shows in the log
    Given the task
      """
      title: "Expense report"
      creator: scott
      owner: alice
      """
    Then the activity log shows the entries
      """
      scott created Expense report
      alice is owner of Expense report
      """

  Scenario: Claiming a task shows in the log
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
      alice is owner of Expense report
      """

  Scenario: Owner delegating a task shows in the log
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
      alice is owner of Expense report
      alice delegated Expense report
      bob is owner of Expense report
      """

  Scenario: Supervisor delegating a task shows in the log
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
      alice is owner of Expense report
      scott delegated Expense report
      bob is owner of Expense report
      """

  Scenario: Releasing a task shows in the log
    Given the task
      """
      title: "Expense report"
      owner: alice
      """
    When alice releases the task "Expense report"
    Then the activity log shows the entries
      """
      alice is owner of Expense report
      alice no longer owner of Expense report
      """

  Scenario: Modifying a task shows in the log
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

  Scenario: Suspending a task shows in the log
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

  Scenario: Resuming a task shows in the log
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

  Scenario: Cancelling a task shows in the log
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

  Scenario: Completing a task shows in the log
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
      alice is owner of Expense report
      alice completed Expense report
      """

  Scenario: Creating new template shows in the log
    Given the template
      """
      title: "TPS report"
      creator: scott
      """
    Then the activity log shows the entries
      """
      scott created the template TPS report
      """

  Scenario: Enabling a template shows in the log
    Given the template
      """
      title: "TPS report"
      creator: scott
      """
    When scott disables the template "TPS report"
    Then the activity log shows the entries
      """
      scott created the template TPS report
      scott disabled the template TPS report
      """

  Scenario: Enabling a template shows in the log
    Given the template
      """
      title: "TPS report"
      creator: scott
      status: disabled
      """
    When scott disables the template "TPS report"
    And scott enables the template "TPS report"
    Then the activity log shows the entries
      """
      scott created the template TPS report
      scott enabled the template TPS report
      """

  Scenario: Changing a template shows in the log
    Given the template
      """
      title: "TPS report"
      creator: scott
      """
    When scott changes the template "TPS report"
    Then the activity log shows the entries
      """
      scott created the template TPS report
      scott changed the template TPS report
      """
