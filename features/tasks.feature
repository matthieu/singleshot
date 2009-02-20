Feature: Task API

  In order to write applications to use Singleshot
  As a developer of these applications
  I want a Web API that allows me to create, monitor and manage tasks.

  Scenario: creating a new task with nothing but title
    Given the person "scott"
    When I am logged in as "scott"
    And I create a new task with this request
    """
    { task: { title: "expenses" }}
    """
    Then the response should be a task
    And the title of the response task should be "expenses"
    And the status of the response task should be "available"
    And the creator of the response task should be "scott"
    And the supervisor of the response task should be "scott"
    And the response task should have no "owner"
 
