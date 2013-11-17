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

To install, clone this github repository and run "bundle install" in the top-level directory.

## Configuration

To configure, copy the file config-TEMPLATE.yml to config.yml and edit it with your Jira connection details.

Web hooks for pull requests can only be configured via the Github API.

You can use the github-pull-request plugin on DEV@cloud/jenkins to set this up for you - but some people prefer not to hand over the "keys to the kinddom".
POST to https://api.github.com/repos/:username/:repo/hooks the following type of data:
{
  "name": "web",
  "active": true,
  "events": ["pull_request"],
  "config": {
    "url": "https://playground.ci.cloudbees.com/github-pull-request-hook/"
  }
}
eg:

curl -u username:password -X POST -d @pullhooks https://api.github.com/repos/:user/:repo/hooks 
where the JSON above is stored in a file called "pullhooks"

GET to https://api.github.com/repos/:username/:repo/hooks to check if the webhook you created has the proper event applied.
You will see the URL in the admin section of your repo, and you can change it. There will be no mention of what events the URL fires on, but it should stick to pull_request.

by [Francesco Balestrieri](bale@balenet.com).