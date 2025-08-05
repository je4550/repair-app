module Constraints
  class BaseDomainConstraint
    def matches?(request)
      # Check if this is a base domain (no subdomain or Heroku app domain)
      subdomain = request.subdomain
      
      # Empty subdomain
      return true if subdomain.blank?
      
      # Heroku app domains like autoplanner-staging-17cdee2cd69f.herokuapp.com
      # should be treated as base domains
      if request.host.match?(/\.herokuapp\.com$/)
        # Check if subdomain matches Heroku app pattern (appname-hash)
        return true if subdomain.match?(/^[a-z0-9-]+-[a-f0-9]{16}$/)
      end
      
      false
    end
  end
  
  class TenantSubdomainConstraint
    def matches?(request)
      # This is a tenant subdomain if it's NOT a base domain
      !BaseDomainConstraint.new.matches?(request)
    end
  end
end