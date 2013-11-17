# Github-Jira Issue Resolver

Rails application that receives Github web hooks notifications for pull requests, and comments and resolves any referenced issues in Jira. It mimics the syntax used when working with the Github issue tracker.

Any reference to the issue ID (KEY-xxx) or full issue URL in the body of the pull request will cause the same comment to be posted to the corresponding issue in Jira. If the comment indicates that the PR is fixing the issue, the issue will be resolved. An issue will be resolved automatically if the issue ID or URL is preceded by any of the (case insensitive) words _fix, fixes, fixed, resolve, resolves, resolved, close, closes, closed_ and _BUG=_ (the latter seems to be the convention used in the Crosswalk project) 

## Installation

To install, clone this github repository and run "bundle install" in the top-level directory.

## Configuration

To configure, create a copy of the file [config-TEMPLATE.yml](https://github.com/otcshare/jira-github-hooks/blob/master/config/config-TEMPLATE.yml), name it config.yml, and modify it with your Jira connection details. See the template file for details about the configuration options.

Web hooks for pull request events cannot be configured via the Github web UI, but only via the Github API. One must POST to https://api.github.com/repos/:username/:repo/hooks the following type of data:

    {
      "name": "web",
      "active": true,
      "events": ["pull_request"],
      "config": {
        "url": "https://example.com/pull_request/"
      }
    }

eg:

    curl -u username:password -X POST -d @pullhooks https://api.github.com/repos/:user/:repo/hooks 

where the JSON above is stored in a file called "pullhooks"

After this, the URL will appear in the Services section of the repository settings repo, and can be edited.