require 'singleton'
require 'yaml'
require 'jira4r'

module Modules
     
  class JiraHelper

    include Singleton

    attr_reader :resolve_on_merge    

    FIND_ISSUE_REGEXP_TEMPLATE = 
       "(BUG=|fixe?[s|d] *|resolve[s|d]? *|close[s|d]? *)?(http[^ ]+/)?(%{projects})-([0-9]+)"

    def initialize
      @jira_config = YAML.load(File.new "config/config.yml", 'r')
      @jira_projects = @jira_config['projects']
      @resolve_on_merge = @jira_config['resolve_on_merge']
      @jira_connection = Jira4R::JiraTool.new(2, @jira_config['address'])

      # Optional SSL parameters
      if @jira_config['ssl_version'] != nil
        @jira_connection.driver.streamhandler.client.ssl_config.ssl_version = @jira_config['ssl_version']
      end
      if @jira_config['verify_certificate'] == false
        @jira_connection.driver.options['protocol.http.ssl_config.verify_mode'] = OpenSSL::SSL::VERIFY_NONE
      end

      @jira_connection.login(@jira_config['username'], @jira_config['password'])
      @regexp = Regexp.new(FIND_ISSUE_REGEXP_TEMPLATE % {projects: @jira_projects.join('|')},
        Regexp::IGNORECASE)
    end

    def add_comment(issue_id, body)
      
      rc = Jira4R::V2::RemoteComment.new
      rc.body = body
      
      begin
        @jira_connection.addComment issue_id, rc 
      rescue
        Rails.logger.error "Failed to add comment to issue #{issue_id}"
      else
        Rails.logger.debug "Successfully added comment to issue #{issue_id}"
      end
    end
    
    def resolve(issue_id)
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
  
    def scan_issues(body)
      body.scan @regexp do |match|
        yield !match[0].nil?, match[2] + '-' + match[3]
      end
    end
  end
  
end