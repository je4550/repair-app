# Set tenant when user is loaded from session
Warden::Manager.after_set_user do |user, auth, opts|
  if user && user.respond_to?(:shop) && user.shop
    ActsAsTenant.current_tenant = user.shop
  end
end

# Clear tenant on logout
Warden::Manager.before_logout do |user, auth, opts|
  ActsAsTenant.current_tenant = nil
end

# Ensure tenant is set during authentication
Warden::Manager.after_authentication do |user, auth, opts|
  if user && user.respond_to?(:shop) && user.shop
    ActsAsTenant.current_tenant = user.shop
  end
end