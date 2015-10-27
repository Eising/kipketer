Feature: Go to the schedule new test link and fill in some values

Scenario: Filling in a schedule
        Given I am on the home page
        When I follow "Schedule New Test"
        When I fill in the following:
          | bo_CRID              | NKA-999999    |
          | bo_CompanyName       | Test          |
          | bo_LocationAFullName | Testvej 12    |
          | bo_CPE.CPEConnectionSpeed | 100           |
          | deadline             | 31-12-2020    |
        And I select "eVPN dr3.hors" from "form_id"
        And I press "submitbtn"
        Then I should see "Configure Test"

