class Reports::ServicesController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!

  def index
    @date_range = params[:date_range] || '30_days'
    @start_date, @end_date = date_range_for(@date_range)
    
    # Service performance metrics
    @total_services_performed = total_services_in_period
    @previous_services_performed = previous_period_services
    @services_change = calculate_percentage_change(@previous_services_performed, @total_services_performed)
    
    # Service revenue
    @total_service_revenue = service_revenue_in_period
    @previous_service_revenue = previous_period_service_revenue
    @revenue_change = calculate_percentage_change(@previous_service_revenue, @total_service_revenue)
    
    # Average service price
    @avg_service_price = @total_services_performed > 0 ? @total_service_revenue / @total_services_performed : 0
    @previous_avg_price = previous_avg_service_price
    @price_change = calculate_percentage_change(@previous_avg_price, @avg_service_price)
    
    # Service completion rate
    @completion_rate = service_completion_rate
    
    # Most popular services
    @popular_services = most_popular_services
    
    # Service revenue breakdown
    @service_revenue_breakdown = service_revenue_breakdown
    
    # Service performance trends
    @service_trends = service_performance_trends
    
    # Service duration analysis
    @avg_service_duration = average_service_duration
    @duration_by_service = duration_by_service_type
    
    # Service pricing analysis
    @pricing_analysis = service_pricing_analysis
    
    # Service categories performance
    @category_performance = service_category_performance
  end

  private

  def date_range_for(range)
    case range
    when '7_days'
      [7.days.ago.beginning_of_day, Time.current.end_of_day]
    when '30_days'
      [30.days.ago.beginning_of_day, Time.current.end_of_day]
    when '90_days'
      [90.days.ago.beginning_of_day, Time.current.end_of_day]
    when '1_year'
      [1.year.ago.beginning_of_day, Time.current.end_of_day]
    when 'custom'
      start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago
      end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current
      [start_date.beginning_of_day, end_date.end_of_day]
    else
      [30.days.ago.beginning_of_day, Time.current.end_of_day]
    end
  end

  def appointment_services_in_period
    @appointment_services_in_period ||= AppointmentService.joins(appointment: { customer: { location: { region: :shop } } })
                                                         .where(customers: { location_id: location_ids_for_current_user })
                                                         .joins(:appointment)
                                                         .where(appointments: { status: 'completed', updated_at: @start_date..@end_date })
  end

  def total_services_in_period
    appointment_services_in_period.count
  end

  def service_revenue_in_period
    appointment_services_in_period.sum(:price_cents) / 100.0
  end

  def previous_period_services
    days_diff = (@end_date - @start_date).to_i
    prev_start = @start_date - days_diff.days
    prev_end = @start_date - 1.day
    
    AppointmentService.joins(appointment: { customer: { location: { region: :shop } } })
                     .where(customers: { location_id: location_ids_for_current_user })
                     .joins(:appointment)
                     .where(appointments: { status: 'completed', updated_at: prev_start..prev_end })
                     .count
  end

  def previous_period_service_revenue
    days_diff = (@end_date - @start_date).to_i
    prev_start = @start_date - days_diff.days
    prev_end = @start_date - 1.day
    
    AppointmentService.joins(appointment: { customer: { location: { region: :shop } } })
                     .where(customers: { location_id: location_ids_for_current_user })
                     .joins(:appointment)
                     .where(appointments: { status: 'completed', updated_at: prev_start..prev_end })
                     .sum(:price_cents) / 100.0
  end

  def previous_avg_service_price
    prev_count = previous_period_services
    prev_revenue = previous_period_service_revenue
    
    prev_count > 0 ? prev_revenue / prev_count : 0
  end

  def calculate_percentage_change(old_value, new_value)
    return 0 if old_value == 0 && new_value == 0
    return 100 if old_value == 0 && new_value > 0
    return -100 if old_value > 0 && new_value == 0
    
    ((new_value - old_value) / old_value * 100).round(1)
  end

  def service_completion_rate
    total_appointments = Appointment.joins(customer: { location: { region: :shop } })
                                   .where(customers: { location_id: location_ids_for_current_user })
                                   .where(appointments: { scheduled_at: @start_date..@end_date })
                                   .count
    
    completed_appointments = Appointment.joins(customer: { location: { region: :shop } })
                                       .where(customers: { location_id: location_ids_for_current_user })
                                       .where(appointments: { status: 'completed' })
                                       .where(appointments: { scheduled_at: @start_date..@end_date })
                                       .count
    
    total_appointments > 0 ? (completed_appointments.to_f / total_appointments * 100).round(1) : 0
  end

  def most_popular_services
    appointment_services_in_period.joins(:service)
                                 .group('services.name')
                                 .select('services.name, services.description, COUNT(*) as service_count, SUM(appointment_services.price_cents) as total_revenue')
                                 .order('service_count DESC')
                                 .limit(10)
                                 .map do |result|
                                   {
                                     name: result.name,
                                     description: result.description,
                                     count: result.service_count,
                                     revenue: result.total_revenue / 100.0,
                                     avg_price: result.total_revenue / 100.0 / result.service_count
                                   }
                                 end
  end

  def service_revenue_breakdown
    appointment_services_in_period.joins(:service)
                                 .group('services.name')
                                 .sum(:price_cents)
                                 .transform_values { |cents| cents / 100.0 }
                                 .sort_by { |_, revenue| -revenue }
                                 .first(10)
  end

  def service_performance_trends
    # Last 30 days of service performance
    30.times.map do |i|
      date = i.days.ago.to_date
      date_start = date.beginning_of_day
      date_end = date.end_of_day
      
      services_count = AppointmentService.joins(appointment: { customer: { location: { region: :shop } } })
                                        .where(customers: { location_id: location_ids_for_current_user })
                                        .joins(:appointment)
                                        .where(appointments: { status: 'completed', updated_at: date_start..date_end })
                                        .count
      
      {
        date: date.strftime('%m/%d'),
        count: services_count
      }
    end.reverse
  end

  def average_service_duration
    # Calculate average duration from scheduled appointments
    completed_appointments = Appointment.joins(customer: { location: { region: :shop } })
                                       .where(customers: { location_id: location_ids_for_current_user })
                                       .where(appointments: { status: 'completed' })
                                       .where(appointments: { updated_at: @start_date..@end_date })
    
    total_duration = completed_appointments.joins(:appointment_services)
                                         .joins('JOIN services ON appointment_services.service_id = services.id')
                                         .sum('services.duration_minutes')
    
    appointment_count = completed_appointments.count
    
    appointment_count > 0 ? (total_duration / appointment_count).round : 0
  end

  def duration_by_service_type
    Service.where(location_id: location_ids_for_current_user)
           .joins(:appointment_services)
           .joins('JOIN appointments ON appointment_services.appointment_id = appointments.id')
           .joins('JOIN customers ON appointments.customer_id = customers.id')
           .where(customers: { location_id: location_ids_for_current_user })
           .where(appointments: { status: 'completed', updated_at: @start_date..@end_date })
           .group('services.name')
           .average('services.duration_minutes')
           .transform_values { |duration| duration.to_i }
           .sort_by { |_, duration| -duration }
           .first(10)
  end

  def service_pricing_analysis
    # Compare actual prices vs standard prices
    service_pricing = appointment_services_in_period.joins(:service)
                                                   .group('services.name')
                                                   .select('services.name, services.price_cents as standard_price, AVG(appointment_services.price_cents) as avg_actual_price')
                                                   .map do |result|
                                                     standard_price = result.standard_price&.to_f || 0.0
                                                     avg_actual_price = result.avg_actual_price&.to_f || 0.0
                                                     
                                                     # Calculate price variance, handling division by zero
                                                     price_variance = if standard_price > 0
                                                       ((avg_actual_price - standard_price) / standard_price * 100).round(1)
                                                     else
                                                       0.0
                                                     end
                                                     
                                                     {
                                                       name: result.name,
                                                       standard_price: standard_price / 100.0,
                                                       avg_actual_price: avg_actual_price / 100.0,
                                                       price_variance: price_variance
                                                     }
                                                   end
    
    service_pricing.sort_by { |s| s[:price_variance].abs }.reverse.first(10)
  end

  def service_category_performance
    # Group services by category (based on service name patterns)
    categories = {
      'Oil & Filters' => ['Oil Change', 'Filter Replacement', 'Air Filter', 'Cabin Air Filter'],
      'Brakes' => ['Brake', 'Braking'],
      'Engine' => ['Engine', 'Spark Plug', 'Fuel System'],
      'Transmission' => ['Transmission'],
      'Cooling' => ['Coolant', 'Radiator'],
      'Electrical' => ['Battery', 'Alternator', 'Electrical'],
      'Tires & Alignment' => ['Tire', 'Wheel', 'Alignment'],
      'AC & Heating' => ['AC', 'Air Conditioning', 'Heating'],
      'Diagnostic' => ['Diagnostic', 'Inspection'],
      'Other' => []
    }
    
    category_stats = {}
    
    categories.each do |category, keywords|
      if keywords.empty?
        # "Other" category - services that don't match any keywords
        all_keywords = categories.except('Other').values.flatten
        if all_keywords.any?
          conditions = all_keywords.map { |keyword| "services.name LIKE ?" }
          values = all_keywords.map { |keyword| "%#{keyword}%" }
          services_in_category = appointment_services_in_period.joins(:service)
                                                              .where.not(conditions.join(' OR '), *values)
        else
          services_in_category = appointment_services_in_period.joins(:service)
        end
      else
        conditions = keywords.map { |keyword| "services.name LIKE ?" }
        values = keywords.map { |keyword| "%#{keyword}%" }
        services_in_category = appointment_services_in_period.joins(:service)
                                                            .where(conditions.join(' OR '), *values)
      end
      
      count = services_in_category.count
      revenue = services_in_category.sum(:price_cents) / 100.0
      
      category_stats[category] = {
        count: count,
        revenue: revenue,
        avg_price: count > 0 ? revenue / count : 0
      }
    end
    
    category_stats.select { |_, stats| stats[:count] > 0 }
                  .sort_by { |_, stats| -stats[:revenue] }
  end
end