Features: Using forms to peform the task

  Background:
    Given the person scott
    And the person me
    And this task
      """
      title: "Absence request"
      creator: scott
      owner: me
      form:
        html: "{{ creator.fullname }} requested leave of absence.
               <label><input type='radio' name='data[accept]' value='true'> Accept</label>
               <label><input type='radio' name='data[accept]' value='false'> Deny</label>
               Comment: <textarea name='data[comment]'></textarea>"
      """

  Scenario: See task form with relevant details
    When I login
    And I go to the task "Absence request"
    And I am on the frame "frame"
    Then I should see "Scott requested leave of absence"

  Scenario: Fill in task form and save for later
    When I login
    And I go to the task "Absence request"
    And I am on the frame "frame"
    And I choose "data[accept]"
    And I fill in "data[comment]" with "enjoy"
    And I press "Save"
    Then I should be on the form for "Absence request"
    And the task "Absence request" should be active
    And the task "Absence request" data should have accept="true"
    And the task "Absence request" data should have comment="enjoy"

  Scenario: Fill in task form and complete task
    When I login
    And I go to the task "Absence request"
    And I am on the frame "frame"
    And I choose "data[accept]"
    And I fill in "data[comment]" with "enjoy"
    And I press "Done"
    Then I should see be redirected with a script to the homepage
    And the task "absence request" should be completed
    And the task "absence request" data should have accept="true"
    And the task "absence request" data should have comment="enjoy"
