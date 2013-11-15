require 'jira4r/jira_tool.rb'
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
        
    payload = ActiveSupport::JSON.decode params[:payload]
    
    r = Regexp.new("(fixe?[s|d] *|resolve[s|d]? *|close[s|d]? *)?(http[^ ]+/)?(#{@jira_projects.join('|')})-([0-9]+)",
      Regexp::IGNORECASE)
    pull_request = payload["pull_request"]
    user = pull_request["user"]
    repo = pull_request["head"]["repo"]

    user_string = "[#{user["login"]}|#{user["html_url"]}]"
    pr_string = "[Pull Request ##{payload["number"]}|#{pull_request["html_url"]}]"
    
    rc = Jira4R::V2::RemoteComment.new
    
    if payload["action"] == "opened"
      rc.body = "(i) #{user_string} referenced this issue in project [#{repo["name"]}|#{repo["html_url"]}]:\n\n"\
        "*#{pr_string}:* _\"#{pull_request["title"]}\"_"
    else
      rc.body = "(/) #{user_string} resolved this issue with *#{pr_string}*"
    end
    
    pull_request["body"].scan(r) do |match| 
      
      should_resolve = !match[0].nil? && payload["action"] == "closed"
      bug_id = match[2] + '-' + match[3]
        
      Rails.logger.debug bug_id + ' ' + rc.body

      # Comment on this issue
      begin
        @jira_connection.addComment(bug_id, rc)
      rescue
        Rails.logger.error("Failed to add comment to issue %s" % [bug_id])
      else
        Rails.logger.debug("Successfully added comment to issue %s" % [bug_id])
      end
      
      # Close the issue if needed
      if should_resolve
        begin
          available_actions = @jira_connection.getAvailableActions bug_id
          resolve_action = available_actions.find {|s| s.name == 'Resolve Issue'}
          if !resolve_action.nil?
            @jira_connection.progressWorkflowAction(bug_id, resolve_action.id.to_s, [])
          else
            Rails.logger.debug("Not allowed to resolve issue %s. Allowable actions: %s" % [bug_id, (available_actions.map {|s| s.name}).to_s])
          end
        rescue StandardError => e
          Rails.logger.error("Failed to resolve issue %s : %s" % [bug_id, e.to_s])
        else
          Rails.logger.debug("Successfully resolved issue %s" % [bug_id])
        end
      end
    end
    
    render :nothing => true, :status => 200
    
  end
  
end