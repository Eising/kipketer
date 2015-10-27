@important

Feature: Submitting a simple template

Scenario: Submitting a simple template
        Given I am on the home page
        When I follow "Manage Templates"
        Then I should see "Add template"
        When I follow "Add template"
        Then I should see "Add new template"
        When I fill in "contents" with "{{test}}"
        And I fill in "contents_deconfigure" with "{{test}}"
        And I fill in the following:
            | name          | Testtemplate    |
            | description   | A Test Template |
        And I select "CPE" from "type"
        And I press "submitbtn"
        Then I should see "Setup tags"
        When I select "Validates Vlan" from "tag_test"
        And I press "submitbtn"
        Then I should see "View templates"

Scenario: Submitting another simple template
        Given I am on the home page
        When I follow "Manage Templates"
        Then I should see "Add template"
        When I follow "Add template"
        Then I should see "Add new template"
        When I fill in "contents" with "{{variable}}"
        And I fill in "contents_deconfigure" with "{{variable}}"
        And I fill in the following:
            | name          | Testtemplate2    |
            | description   | Another Test Template |
        And I select "Backbone" from "type"
        And I press "submitbtn"
        Then I should see "Setup tags"
        When I select "Validates IP addresses" from "tag_variable"
        And I press "submitbtn"
        Then I should see "View templates"


        
