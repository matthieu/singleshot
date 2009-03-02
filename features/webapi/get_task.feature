Feature: Get task using API

  Scenario: viewing a task as JSON object
    Given I am authenticated as scott
    Given the task "expenses" created by scott and assigned to scott
    When I request json representation of the task "expenses"
 

