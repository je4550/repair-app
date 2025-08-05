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
      if record
        begin
          shop = record.location&.region&.shop
          if shop
            ActsAsTenant.current_tenant = shop
          else
            Rails.logger.warn "User #{record.id} has incomplete hierarchy: location=#{record.location_id}, location_exists=#{!!record.location}, region_exists=#{!!record.location&.region}, shop_exists=#{!!record.location&.region&.shop}"
          end
        rescue => e
          Rails.logger.error "Error loading tenant for user #{record.id}: #{e.message}"
        end
      end
      
      record if record && record.authenticatable_salt == salt
    end
  end
end