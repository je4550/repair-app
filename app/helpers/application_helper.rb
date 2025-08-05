module ApplicationHelper
  include Pagy::Frontend
  
  def demo_shop_url
    if Rails.env.production?
      # On Heroku, construct the full URL with subdomain
      base_host = ENV['APP_DOMAIN'] || request.host
      "https://jeffs.#{base_host}"
    else
      # In development, use the standard subdomain URL
      root_url(subdomain: 'jeffs')
    end
  end
  
  def appointment_status_color(status)
    case status
    when 'scheduled'
      '#17a2b8'
    when 'confirmed'
      '#007bff'
    when 'in_progress'
      '#ffc107'
    when 'completed'
      '#28a745'
    when 'cancelled'
      '#6c757d'
    else
      '#6c757d'
    end
  end
end
