Feature: Sending Webhook notifications

  Scenario: Use Webhook to notify of task completion
    Given I am authenticated as scott
    When I post this request to create a task
      """
      { task: {
          title:        "expenses",
          webhooks: [
            { event: "completed",
              url: "http://localhost:1234/hook" }
          ]
      } }
      """
    And scott claims the task "expenses"
    And scott completes the task "expenses"
    Then the resource http://localhost:1234/hook received POST notification

