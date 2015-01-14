Copyright (c) 2014 Francesco Balestrieri

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

require 'modules'
require 'set'

class PullRequestController < ApplicationController

  include Modules
  respond_to :json

  def post

    payload = ActiveSupport::JSON.decode params[:payload]
    
    if payload["action"] == "closed"
      comment = closed_comment_from payload      
    else # "opened", "reopened", "synchronize"
      comment = opened_comment_from payload
    end
    
    jira = JiraHelper.instance
    processed_issues = Set.new
    
    jira.scan_issues payload["pull_request"]["body"] do | should_resolve, issue_id |       
      #skip already processed issues
      if processed_issues.add?(issue_id)
        jira.add_comment issue_id, comment
      
        if should_resolve && jira.resolve_on_merge && payload["action"] == "closed"
          jira.resolve issue_id
        end
      end
    end
    
    render :nothing => true, :status => 200  
  end
  
  def opened_comment_from(json_payload)
    
    pr = json_payload["pull_request"]
    user = pr["user"]
    repo = pr["head"]["repo"]

    JiraHelper.instance.opened_pr_template %
      { user_id: user["login"], user_url: user["html_url"],
        repo_name: repo["name"], repo_url: repo["html_url"],
        pr_number: json_payload["number"], pr_url: pr["html_url"],
        pr_title: pr["title"] }
  end

  def closed_comment_from(json_payload)   
  
    pr = json_payload["pull_request"]
    user = pr["user"]
    repo = pr["head"]["repo"]
    
    JiraHelper.instance.closed_pr_template % 
      { user_id: user["login"], user_url: user["html_url"],
        pr_number: json_payload["number"],
        pr_url: pr["html_url"], pr_title: pr["title"] }
  end

end