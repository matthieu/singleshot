Features: Using templates to start new tasks

  Background:
    Given the template
      """
      title: "Absence request"
      description: "Request leave of absence"
      form:
        html: "<input type='text' name='data[date]'>"
      """

  Scenario: See template listed on front page
    When I login
    And I go to the homepage
    Then I should see "Absence request"

  Scenario: Start new task when I open the template
    When I login
    And I go to the homepage
    And I follow "Absence request"
    Then I should be on the task "Absence request"
    And I should see "Request leave of absence"

  Scenario: Perfom task created from template
    When I login
    And I go to the homepage
    And I follow "Absence request"
    And I am on the frame "frame"
    And I fill in "data[date]" with "tomorrow"
    And I press "Done"
    Then I should see be redirected with a script to the homepage
    And the task "absence request" should be completed
    And the task "absence request" data should have accept="true"
    And the task "absence request" data should have comment="enjoy"



  Scenario: Use template to perform task and save state
    When I login
    And I go to the homepage
    And I follow "Absence request"

