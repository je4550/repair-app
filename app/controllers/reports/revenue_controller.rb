class Reports::RevenueController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!

  def index
    @date_range = params[:date_range] || '30_days'
    @start_date, @end_date = date_range_for(@date_range)
    
    # Total revenue metrics
    @total_revenue = completed_appointments.sum(:total_price_cents) / 100.0
    @previous_period_revenue = previous_period_revenue
    @revenue_change = calculate_percentage_change(@previous_period_revenue, @total_revenue)
    
    # Average ticket size
    @avg_ticket_size = @total_revenue > 0 ? @total_revenue / completed_appointments.count : 0
    @previous_avg_ticket = previous_avg_ticket_size
    @ticket_change = calculate_percentage_change(@previous_avg_ticket, @avg_ticket_size)
    
    # Appointment count
    @total_appointments = completed_appointments.count
    @previous_appointments = previous_period_appointments
    @appointment_change = calculate_percentage_change(@previous_appointments, @total_appointments)
    
    # Daily revenue for chart
    @daily_revenue = daily_revenue_data
    
    # Revenue by service type
    @service_revenue = service_revenue_breakdown
    
    # Top performing services
    @top_services = top_services_by_revenue
    
    # Monthly trends (last 12 months)
    @monthly_trends = monthly_revenue_trends
  end

  private

  def completed_appointments
    @completed_appointments ||= Appointment.joins(customer: :shop)
                                          .where(shops: { id: current_user.shop_id })
                                          .where(appointments: { status: 'completed' })
                                          .where(appointments: { updated_at: @start_date..@end_date })
  end

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

  def previous_period_revenue
    days_diff = (@end_date - @start_date).to_i
    prev_start = @start_date - days_diff.days
    prev_end = @start_date - 1.day
    
    Appointment.joins(customer: :shop)
               .where(shops: { id: current_user.shop_id })
               .where(appointments: { status: 'completed' })
               .where(appointments: { updated_at: prev_start..prev_end })
               .sum(:total_price_cents) / 100.0
  end

  def previous_avg_ticket_size
    days_diff = (@end_date - @start_date).to_i
    prev_start = @start_date - days_diff.days
    prev_end = @start_date - 1.day
    
    prev_appointments = Appointment.joins(customer: :shop)
                                  .where(shops: { id: current_user.shop_id })
                                  .where(appointments: { status: 'completed' })
                                  .where(appointments: { updated_at: prev_start..prev_end })
    
    prev_revenue = prev_appointments.sum(:total_price_cents) / 100.0
    prev_count = prev_appointments.count
    
    prev_count > 0 ? prev_revenue / prev_count : 0
  end

  def previous_period_appointments
    days_diff = (@end_date - @start_date).to_i
    prev_start = @start_date - days_diff.days
    prev_end = @start_date - 1.day
    
    Appointment.joins(customer: :shop)
               .where(shops: { id: current_user.shop_id })
               .where(appointments: { status: 'completed' })
               .where(appointments: { updated_at: prev_start..prev_end })
               .count
  end

  def calculate_percentage_change(old_value, new_value)
    return 0 if old_value == 0 && new_value == 0
    return 100 if old_value == 0 && new_value > 0
    return -100 if old_value > 0 && new_value == 0
    
    ((new_value - old_value) / old_value * 100).round(1)
  end

  def daily_revenue_data
    # Group by date and sum revenue
    completed_appointments.group("DATE(appointments.updated_at)")
                         .sum(:total_price_cents)
                         .transform_values { |cents| cents / 100.0 }
                         .sort_by { |date, _| Date.parse(date) }
                         .to_h
  end

  def service_revenue_breakdown
    # Get revenue by service through appointment_services
    AppointmentService.joins(appointment: { customer: :shop })
                     .where(shops: { id: current_user.shop_id })
                     .joins(:appointment)
                     .where(appointments: { status: 'completed', updated_at: @start_date..@end_date })
                     .joins(:service)
                     .group('services.name')
                     .sum(:price_cents)
                     .transform_values { |cents| cents / 100.0 }
                     .sort_by { |_, revenue| -revenue }
                     .first(10)
  end

  def top_services_by_revenue
    AppointmentService.joins(appointment: { customer: :shop })
                     .where(shops: { id: current_user.shop_id })
                     .joins(:appointment)
                     .where(appointments: { status: 'completed', updated_at: @start_date..@end_date })
                     .joins(:service)
                     .group('services.name')
                     .select('services.name, COUNT(*) as service_count, SUM(appointment_services.price_cents) as total_revenue')
                     .order('total_revenue DESC')
                     .limit(5)
                     .map do |result|
                       {
                         name: result.name,
                         count: result.service_count,
                         revenue: result.total_revenue / 100.0,
                         avg_price: result.total_revenue / 100.0 / result.service_count
                       }
                     end
  end

  def monthly_revenue_trends
    # Last 12 months of revenue data
    12.times.map do |i|
      month_start = (i + 1).months.ago.beginning_of_month
      month_end = (i + 1).months.ago.end_of_month
      
      revenue = Appointment.joins(customer: :shop)
                          .where(shops: { id: current_user.shop_id })
                          .where(appointments: { status: 'completed' })
                          .where(appointments: { updated_at: month_start..month_end })
                          .sum(:total_price_cents) / 100.0
      
      {
        month: month_start.strftime('%b %Y'),
        revenue: revenue
      }
    end.reverse
  end
end