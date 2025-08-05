module TenantSafeUser
  extend ActiveSupport::Concern

  included do
    # Override Devise's method to handle tenant loading
    def self.serialize_from_session(key, salt)
      # Find the user without tenant restrictions
      record = ActsAsTenant.without_tenant do
        where(id: key).first
      end
      
      # Set the tenant if user exists
      if record && record.shop
        ActsAsTenant.current_tenant = record.shop
      end
      
      record if record && record.authenticatable_salt == salt
    end
  end
end