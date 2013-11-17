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