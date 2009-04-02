Features: Using forms to peform the task

  Background:
    Given the person scott
    And this task
      """
      title: "absence request"
      creator: scott
      owner: me
      form:
        html: "{{ creator.fullname }} requested leave of absence.
               <label><input type='radio' name='task[accept]' value='true'> Accept</label>
               <label><input type='radio' name='task[accept]' value='false'> Deny</label>
               Comment:<textarea name='task[comment]'></textarea>"
      """

  Scenario: See task form with relevant details
    When I login
    And I view the task "absence request"
    And I choose the frame "task_frame"
    Then I should see "Scott requested leave of absence"

  Scenario: Fill in task form and complete task
    When I login
    And I view the task "absence request"
    And I choose the frame "task_frame"
    And I choose "task[accept]"
    And I fill in "task[comment]" with "enjoy"
    And I press "Done"
    Then I should be viewing the home page
    And the task "absence request" should be completed
    And the task "absence request" data should have accept="true"
    And the task "absence request" data should have comment="enjoy"

  Scenario: Fill in task form and save for later
    When I login
    And I view the task "absence request"
    And I choose the frame "task_frame"
    And I choose "task[accept]"
    And I fill in "task[comment]" with "enjoy"
    And I press "Save"
    Then the task "absence request" should be active
    And the task "absence request" data should have accept="true"
    And the task "absence request" data should have comment="enjoy"
