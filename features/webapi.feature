Feature: WebAPI

  Scenario: creating a new task
    Given I am authenticated as scott
    When I post this request to create a task
      """
      { task: { title: "expenses" } }
      """
    Then the response should be a new task
    And the response task title should be "expenses"
    And the response task status should be "available"
    And the response task should have no description
    And the response task should have no language
    And the response task priority should be 2
    And the response task should have no due_on
    And the response task should have no start_on
    And the response task data should be {}
    And the response task creator should be scott
    And the response task supervisor should be scott


  Scenario: creating a task with specific attributes
    Given I am authenticated as scott
    When I post this request to create a task
      """
      { task: {
          title:        "expenses",
          description:  "please submit your expense report",
          language:     "en-geek",
          priority:     1,
          due_on:       "2009-01-16",
          start_on:     "2009/01/12",
          data:         { foo: "bar" }
      } }
      """
    Then the response should be a new task
    And the response task title should be "expenses"
    And the response task description should be "please submit your expense report"
    And the response task language should be "en-geek"
    And the response task priority should be 1
    And the response task due_on should be Fri, 16 Jan 2009
    And the response task start_on should be Mon, 12 Jan 2009
    And the response task data should be {"foo"=>"bar"}


  Scenario: creating a task with specific taskholders
    Given I am authenticated as scott
    And the person alice
    And the person bob
    When I post this request to create a task
      """
      { task: {
          title: "From Alice to Bob",
          creator: "alice",
          owner: "bob"
      } }
      """
    Then the response task creator should be alice
    Then the response task owner should be bob


  Scenario: viewing a task as JSON object
    Given I am authenticated as scott
    Given the task "expenses" created by scott and assigned to scott
    When I request json representation of the task "expenses"

