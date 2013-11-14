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

    rc = Jira4R::V2::RemoteComment.new
    rc.body = "_[#{user["login"]}|#{user["html_url"]}] referenced this issue in project [#{repo["name"]}|#{repo["html_url"]}]_\n\n"\
      "*[Pull request ##{payload["number"]}|#{pull_request["html_url"]}]:* #{pull_request["title"]}"
    # pr_details = "[PR ##{payload["number"]}|#{pull_request["html_url"]}] on branch #{pull_request["head"]["ref"]}"
    
    pull_request["body"].scan(r) do |match| 
      
      should_resolve = !match[0].nil?
      bug_id = match[2] + '-' + match[3]
      # rc.body = "#{should_resolve ? 'Will be resolved by' : 'Mentioned by'} " + pr_details
        
      Rails.logger.debug bug_id + ' ' + rc.body
      
      # Comment on this issue
      begin
        @jira_connection.addComment(bug_id, rc)
      rescue
        Rails.logger.error("Failed to add comment to issue %s" % [bug_id])
      else
        Rails.logger.debug("Successfully added comment to issue %s" % [bug_id])
      end
    end
    
    render :nothing => true, :status => 200
    
  end
  

end
