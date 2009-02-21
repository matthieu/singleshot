Feature: Creating task using API

  In order to write applications to use Singleshot
  As a developer of these applications
  I want a Web API that allows me to create, monitor and manage tasks.

  Scenario: creating a new task
    Given I am authenticated as scott
    When I post this request to create a task
      """
      { task: { title: "expenses" }}
      """
    Then the response should be a new task
    And the title of the task should be "expenses"
    And the status of the task should be "available"
    And the creator of the task should be "scott"
    And the supervisor of the task should be "scott"

