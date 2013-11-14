class PullRequestController < ApplicationController
  
  respond_to :json
  
  def handle
        
    payload = ActiveSupport::JSON.decode params[:payload]

    projects = ["XWALK", "TEST"]
    r = Regexp.new("(fixe?[s|d] ?|resolve[s|d]? ?|close[s|d]? ?)?(#{projects.join('|')})-([0-9]+)", Regexp::IGNORECASE)
    pull_request = payload["pull_request"]
    
    pull_request["body"].scan(r) do |match| 
      
      should_resolve = !match[0].nil?
      bug_id = match[1] + '-' + match[2]
      comment = "#{should_resolve ? 'Will be resolved by' : 'Mentioned by'} " \
        "[PR ##{payload["number"]}|#{pull_request["html_url"]}] on branch #{pull_request["head"]["ref"]}"
      Rails.logger.debug comment
    end
    
    render :nothing => true, :status => 200
    
  end
end
