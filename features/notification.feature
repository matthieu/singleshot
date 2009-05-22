Features: Sending notification

  Background:
    Given I am authenticated

  Scenario: Seeing unread message count
    Given the notification
    """
    subject: "Mark your calendar"
    recipients: me
    """
    When I go to the homepage
    Then I should see "Inbox 1"

  Scenario: Checking the inbox
    Given the notification
    """
    subject: "Mark your calendar"
    body:    "Cool event coming up"
    recipients: me
    """
    When I go to the inbox
    Then I should see "Inbox 1"
    And I should see "Mark your calendar"
    And I should see "Cool event coming up"

  Scenario: Reading notification
    Given the notification
    """
    subject: "Mark your calendar"
    body:    "Cool event coming up"
    recipients: me
    """
    When I go to the inbox
    And I follow "Mark your calendar"
    Then I should not see "Inbox 1"
    And I should see "Mark your calendar"
    And I should see "Cool event coming up"

  Scenario: Receiving notification by e-mail
    Given the notification
    """
    subject: "Mark your calendar"
    body:    "Cool event coming up"
    recipients: me
    """
    Then I should receive the email
    """
    From:     notifications@example.com
    Reply-To: noreply@example.com
    To:       me@example.com
    Subject: "Mark your calendar"
    Body:    "Cool event coming up"
    """

  Scenario: Creating notification using API
    When I post this request to /notifications
      """
      { notification: {
        subject:    "Mark your calendar",
        body:       "Cool event coming up",
        recipients: [ 'me' ],
        priority:   1
      } }
      """
    And I go to the inbox
    Then I should see "Mark your calendar"
    And I follow "Mark your calendar"
    Then I should see "Mark your calendar"
    And I should see "Cool event coming up"
    Then I should receive the email
    """
    From:     notifications@example.com
    Reply-To: noreply@example.com
    To:       me@example.com
    Subject: "Mark your calendar"
    Body:    "Cool event coming up"
    """
