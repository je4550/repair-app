module TenantScoped
  extend ActiveSupport::Concern

  included do
    set_current_tenant_through_filter
    prepend_before_action :set_tenant
    helper_method :current_shop, :current_location, :current_region
  end

  private

  def set_tenant
    # First check if we're on a subdomain
    if request.subdomain.present? && request.subdomain != 'www'
      # If accessing via subdomain, find the shop
      shop = Shop.find_by(subdomain: request.subdomain, active: true)
      if shop
        set_current_tenant(shop)
      else
        # Shop not found, redirect to sign in
        redirect_to new_user_session_url(host: ENV['APP_DOMAIN'] || request.domain), alert: 'Shop not found', allow_other_host: true
      end
    elsif user_signed_in?
      # If user is signed in but no subdomain, use their shop through location
      set_current_tenant(current_user.location.region.shop)
    else
      # No tenant set - redirect to sign in page
      unless public_controller?
        redirect_to new_user_session_path, alert: 'Please sign in to continue'
      end
    end
  end

  def current_shop
    current_tenant
  end
  
  def current_location
    # Check if admin/manager has selected a different location
    if user_signed_in? && (current_user.admin? || current_user.manager?) && session[:current_location_id]
      @current_location ||= ActsAsTenant.without_tenant do
        Location.find_by(id: session[:current_location_id])
      end
    end
    
    # Fall back to user's assigned location
    @current_location ||= if user_signed_in?
      current_user.location
    else
      # For subdomain access, get the default location for the shop
      current_shop&.locations&.first
    end
  end
  
  def current_region
    current_location&.region
  end
  
  # Helper methods for report aggregation
  def location_ids_for_current_user
    case report_scope
    when 'location'
      [current_location.id]
    when 'region'
      current_region.locations.pluck(:id)
    when 'company'
      current_shop.regions.joins(:locations).pluck('locations.id')
    else
      [current_location.id] # default to location
    end
  end
  
  def report_scope
    # Default to location level, but allow override via params
    params[:scope] || 'location'
  end

  def public_controller?
    # Define controllers that don't require a tenant
    devise_controller? ||
    controller_name == 'pages' ||
    controller_name == 'shops'
  end

  def after_sign_in_path_for(resource)
    # Redirect to shop subdomain after sign in
    if resource.is_a?(User) && resource.location&.region&.shop.present?
      root_url(subdomain: resource.location.region.shop.subdomain)
    else
      super
    end
  end
end