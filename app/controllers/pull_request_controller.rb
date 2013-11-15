require 'jira4r'
require 'yaml'

class PullRequestController < ApplicationController
  
  respond_to :json

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
    rc.body = create_comment_from payload
        
    r = Regexp.new("(fixe?[s|d] *|resolve[s|d]? *|close[s|d]? *)?(http[^ ]+/)?(#{@jira_projects.join('|')})-([0-9]+)",
      Regexp::IGNORECASE)
          
    payload["pull_request"]["body"].scan(r) do |match| 
      
      resolve_issue = !match[0].nil? && payload["action"] == "closed"
      issue_id = match[2] + '-' + match[3]

      # Comment on this issue
      begin
        @jira_connection.addComment(issue_id, rc)
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
            @jira_connection.progressWorkflowAction(issue_id, resolve_action.id.to_s, [])
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
  
  def create_comment_from(json_payload)
    
    pull_request = json_payload["pull_request"]
    user = pull_request["user"]
    repo = pull_request["head"]["repo"]
    user_string = "[#{user["login"]}|#{user["html_url"]}]"
    pr_string = "[Pull Request ##{json_payload["number"]}|#{pull_request["html_url"]}]"

    if json_payload["action"] == "opened"
      return "(i) #{user_string} referenced this issue in project [#{repo["name"]}|#{repo["html_url"]}]:\n\n"\
        "*#{pr_string}:* _\"#{pull_request["title"]}\"_"
    else
      return "#{user_string} resolved this issue with *#{pr_string}* (/)"
    end
  end
  
end