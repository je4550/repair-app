class PagesController < ApplicationController
  skip_before_action :set_tenant
  
  def home
    Rails.logger.info "=== PAGES#HOME REACHED ==="
    Rails.logger.info "Host: #{request.host}"
    Rails.logger.info "Subdomain: #{request.subdomain}"
  end

  def about
  end

  def pricing
  end

  def contact
  end
end
