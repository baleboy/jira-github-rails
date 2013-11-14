# Github-Jira Issue Resolver

This application handles Github web hooks notifications for commits and pull requests, and comments and/or resolves any referenced issues in Jira. It mimics the syntax used when working with the Github issue tracker.

In a commit comment or pull request body, any reference to the issue ID (KEY-xxx) will cause the same comment to be posted to the corresponding issue in Jira. If the comment indicates that the commit/PR is fixing the issue, the issue will be resolved. To automatically resolve an issue, one of the following forms can be used (following the Github convention):

   * Fix KEY-xxx
   * Fixes KEY-xxx
   * Fixed KEY-xxx
   * Resolve KEY-xxx
   * Resolves KEY-xxx
   * Resolved KEY-xxx
   * Close KEY-xxx
   * Closes KEY-xxx
   * Closed KEY-xxx

## Installation

To install, clone this github repository and run "bundle install" in the top-level directory. Run in a web server of your choice. 

## Configuration

To configure, copy the file config-template.yaml and save it as config.yaml. The template file contains detailed information about each configuration option.

by [Francesco Balestrieri](bale@balenet.com).