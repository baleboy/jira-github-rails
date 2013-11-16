require 'jira4r'
require 'yaml'

class PullRequestController < ApplicationController
  
  respond_to :json

  OPENED_COMMENT_TEMPLATE =
  "(i) [%{user_id}|%{user_url}] referenced this issue in project [%{repo_name}|%{repo_url}]:\n\n"\
  "*[Pull Request %{pr_number}|%{pr_url}]* _\"%{pr_title}\"_"
  
  CLOSED_COMMENT_TEMPLATE = 
    "(/) [%{user_id}|%{user_url}] resolved this issue with *[Pull Request %{pr_number}|%{pr_url}]*"
    
  FIND_ISSUE_REGEXP_TEMPLATE = 
    "(fixe?[s|d] *|resolve[s|d]? *|close[s|d]? *)?(http[^ ]+/)?(%{projects})-([0-9]+)"
      

  def initialize
        
    @jira_config = YAML.load(File.new "config/config.yml", 'r')
    @jira_projects = @jira_config['projects']
    @jira_connection = Jira4R::JiraTool.new(2, @jira_config['address'])

    # Optional SSL parameters
    if @jira_config['ssl_version'] != nil
      @jira_connection.driver.streamhandler.client.ssl_config.ssl_version = @jira_config['ssl_version']
    end
    if @jira_config['verify_certificate'] == false
      @jira_connection.driver.options['protocol.http.ssl_config.verify_mode'] = OpenSSL::SSL::VERIFY_NONE
    end
    
    @jira_connection.login(@jira_config['username'], @jira_config['password'])
  end
  
  def handle
        
    rc = Jira4R::V2::RemoteComment.new
    payload = ActiveSupport::JSON.decode params[:payload]
    
    if payload["action"] == "opened"
      rc.body = opened_comment_from payload
    else # "closed"
      rc.body = closed_comment_from payload
    end
          
    payload["pull_request"]["body"].scan find_issue_regexp do |match| 
      
      resolve_issue = !match[0].nil? && payload["action"] == "closed"
      issue_id = match[2] + '-' + match[3]

      # Comment on this issue
      begin
        @jira_connection.addComment issue_id, rc 
      rescue
        Rails.logger.error "Failed to add comment to issue #{issue_id}"
      else
        Rails.logger.debug "Successfully added comment to issue #{issue_id}"
      end
      
      # Close the issue if needed
      if resolve_issue
        begin
          available_actions = @jira_connection.getAvailableActions issue_id
          if !available_actions.nil? 
            resolve_action = available_actions.find {|s| s.name == 'Resolve Issue'}
          end
          if !resolve_action.nil?
            @jira_connection.progressWorkflowAction issue_id, resolve_action.id.to_s, []
          else
            Rails.logger.debug "Not allowed to resolve issue #{issue_id}. Allowable actions: "\
              "#{(available_actions.map {|s| s.name}).to_s}"
          end
        rescue StandardError => e
          Rails.logger.error "Failed to resolve issue #{issue_id} : #{e.to_s}"
        else
          Rails.logger.debug "Successfully resolved issue #{issue_id}"
        end
      end
    end
    
    render :nothing => true, :status => 200  
  end
  
  def opened_comment_from(json_payload)
    
    pr = json_payload["pull_request"]
    user = pr["user"]
    repo = pr["head"]["repo"]
    
    OPENED_COMMENT_TEMPLATE % 
      { user_id: user["login"], user_url: user["html_url"],
        repo_name: repo["name"], repo_url: repo["html_url"],
        pr_number: json_payload["number"], pr_url: pr["html_url"],
        pr_title: pr["title"] }
  end
  
  def closed_comment_from(json_payload)   

    pr = json_payload["pull_request"]
    user = pr["user"]
    repo = pr["head"]["repo"]
    
    CLOSED_COMMENT_TEMPLATE % 
      { user_id: user["login"], user_url: user["html_url"],
        pr_number: json_payload["number"],
        pr_url: pr["html_url"], pr_title: pr["title"] }
  end
  
  def find_issue_regexp
    Regexp.new(FIND_ISSUE_REGEXP_TEMPLATE % {projects: @jira_projects.join('|')},
      Regexp::IGNORECASE)
  end
  
  
end