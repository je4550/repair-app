module ApplicationHelper
  include Pagy::Frontend
  
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
