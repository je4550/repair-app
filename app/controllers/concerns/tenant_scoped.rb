module TenantScoped
  extend ActiveSupport::Concern

  included do
    set_current_tenant_through_filter
    prepend_before_action :set_tenant
    helper_method :current_shop
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
        redirect_to root_url(subdomain: false), alert: 'Shop not found'
      end
    elsif user_signed_in?
      # If user is signed in but no subdomain, use their shop
      set_current_tenant(current_user.shop)
    else
      # No tenant set - redirect to main site or show selection
      unless public_controller?
        redirect_to root_url(subdomain: false), alert: 'Please select a shop'
      end
    end
  end

  def current_shop
    current_tenant
  end

  def public_controller?
    # Define controllers that don't require a tenant
    devise_controller? ||
    controller_name == 'pages' ||
    controller_name == 'shops'
  end

  def after_sign_in_path_for(resource)
    # Redirect to shop subdomain after sign in
    if resource.is_a?(User) && resource.shop.present?
      root_url(subdomain: resource.shop.subdomain)
    else
      super
    end
  end
end