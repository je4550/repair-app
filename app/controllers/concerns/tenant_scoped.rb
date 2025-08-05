module TenantScoped
  extend ActiveSupport::Concern

  included do
    set_current_tenant_through_filter
    prepend_before_action :set_tenant
    helper_method :current_shop, :current_location, :current_region
  end

  private

  def set_tenant
    # Special handling for Heroku domains
    # On Heroku, the app URL like autoplanner-staging-17cdee2cd69f.herokuapp.com
    # is the base domain, not a subdomain
    is_heroku_base = request.host.match?(/\.herokuapp\.com$/) && 
                     request.subdomain.match?(/^[a-z0-9-]+-[a-f0-9]+$/)
    
    # First check if we're on a subdomain (but not the Heroku base domain)
    if request.subdomain.present? && request.subdomain != 'www' && !is_heroku_base
      # If accessing via subdomain, find the shop
      shop = Shop.find_by(subdomain: request.subdomain, active: true)
      if shop
        set_current_tenant(shop)
      else
        # Shop not found, redirect to base domain (marketing site)
        base_domain = ENV['APP_DOMAIN'] || request.domain
        redirect_to "https://#{base_domain}", alert: 'Shop not found', allow_other_host: true
      end
    elsif user_signed_in?
      # If user is signed in but no subdomain, redirect to their shop subdomain
      if current_user.location&.region&.shop.present?
        redirect_to root_url(subdomain: current_user.location.region.shop.subdomain), allow_other_host: true
      else
        # User has no shop assigned - this shouldn't happen in normal flow
        redirect_to new_user_session_path, alert: 'No shop assigned to your account'
      end
    else
      # No subdomain and not signed in - this is fine for public pages
      # The public_controller? check ensures only public pages are accessible
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