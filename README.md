# Github-Jira Issue Resolver

This application handles Github web hooks notifications for commits and pull requests, and comments and/or resolves any referenced issues in Jira. It mimics the syntax used when working with the Github issue tracker.

In a commit comment or pull request body, any reference to <JIRA-KEY>-xxx will cause the same comment to be posted to the corresponding issue in Jira. If the comment indicates that the commit/PR is fixing the issue, the issue will be resolved. To automatically resolve an issue, one of the following forms can be used (following the Github convention):

   * Fix <JIRA-KEY>-xxx
   * Fixes <JIRA-KEY>-xxx
   * Fixed <JIRA-KEY>-xxx
   * Resolve <JIRA-KEY>-xxx
   * Resolves <JIRA-KEY>-xxx
   * Resolved <JIRA-KEY>-xxx
   * Close <JIRA-KEY>-xxx
   * Closes <JIRA-KEY>-xxx
   * Closed <JIRA-KEY>-xxx

## Installation

To install, clone this github repository and run "bundle install" in the top-level directory. Run in a web server of your choice. 

## Configuration

To configure, copy the file config-template.yaml and save it as config.yaml. The template file contains detailed information about each configuration option.

by [Francesco Balestrieri](bale@balenet.com)).