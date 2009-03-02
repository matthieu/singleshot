Feature: Listing tasks using API

  Scenario: listing recently updated tasks
    Given tasks from sample1.yaml
    And I am authenticated as scott
    When I request to view the updated task list
    Then the response should be a task list
    With the following tasks in this order
    """
    """

  Scenario: listing recently created tasks
    Given tasks from sample1.yaml
    And I am authenticated as scott
    When I request to view the created task list
    Then the response should be a task list
    With the following tasks in this order
    """
    """

  Scenario: listing recently completed tasks
    Given tasks from sample1.yaml
    And I am authenticated as scott
    When I request to view the created task list
    Then the response should be a task list
    With the following tasks in this order
    """
    """
