Feature: Sending Webhook notifications

  Scenario: Use Webhook to notify of task completion
    Given the task
      """
      title: "Absence request"
      owner: me
      webhooks:
      - event: "completed"
        url:   "http://localhost:1234/hook"
      form:
        html: ""
      """
    And the resource http://localhost:1234/hook
    When I login
    And I go to the task "Absence request"
    And I am on the frame "frame"
    And I press "Done"
    Then the resource http://localhost:1234/hook receives POST notification

