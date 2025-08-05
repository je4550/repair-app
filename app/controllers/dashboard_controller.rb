class DashboardController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!
  
  def index
  end
  
  def switch_location
    # Only allow admins and managers to switch locations
    unless current_user.admin? || current_user.manager?
      redirect_to authenticated_root_path, alert: "You don't have permission to switch locations"
      return
    end
    
    location = Location.find_by(id: params[:location_id])
    
    if location && location.region.shop_id == current_shop.id
      # Store the location preference in session
      session[:current_location_id] = location.id
      redirect_to authenticated_root_path, notice: "Switched to #{location.name}"
    else
      redirect_to authenticated_root_path, alert: "Invalid location"
    end
  end
end
