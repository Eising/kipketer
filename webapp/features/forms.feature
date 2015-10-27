@important

Feature: Making a simple form

Scenario: Making a simple form
        Given I am on the home page
        When I follow "Manage Forms"
        Then I should see "Add form"
        When I follow "Add form"
        Then I should see "Add new form"
        When I fill in "name" with "Test"
        And I select "Testtemplate" from "cpe_selector"
        And I select "Testtemplate2" from "backbone_selector"
        And I press "submitbtn"
        Then I should see "Add Form"
        When I fill in the following:
            | name.test | VLAN |
            | tag.test  |      |
            | name.variable | IP |
            | tag.variable  |    |
        And I press "submitbtn"
        Then I should see "Added form #"



