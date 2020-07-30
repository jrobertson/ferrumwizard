# Introducing the FerrumWizard gem

Usage:

    require 'ferrumwizard'

    fw = FerrumWizard.new('https://login.sipgate.com/', debug: false)
    puts fw.login( 'yourusername', 'secret').account.balance #=> £4

In the above example, the FerrumWizard gem is used to retrieve the Sipgate account balance. 

It does by performing the following:

1. Navigating to the login page using a headless browser
2. Searches the page for an input element of type *email*
3. It adds the username to the found input box
4. Searches the page for an input element of type *password*
5. It adds the password to the found input box and the presses enter
6. Iterates through all known page links to convert to methods, complete with click event
7. After having followed a link, any missing method is queried through an at_css request to hopefully return a string value.

## Resources

* ferrumwizard https://rubygems.org/gems/ferrumwizard

ferrum ferrumwizard wizard webscraper


