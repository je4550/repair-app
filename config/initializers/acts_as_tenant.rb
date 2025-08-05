# ActsAsTenant configuration
ActsAsTenant.configure do |config|
  # By default, ActsAsTenant will raise an error if a query is made 
  # without a tenant set. This can be overridden to false if you want 
  # to allow cross-tenant queries in certain situations.
  config.require_tenant = true
end