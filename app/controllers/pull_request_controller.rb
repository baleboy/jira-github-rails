class PullRequestController < ApplicationController
  
  respond_to :json
  
  def handle
        
    payload = ActiveSupport::JSON.decode params[:payload]
    
    render :nothing => true, :status => 200
    
  end
end
