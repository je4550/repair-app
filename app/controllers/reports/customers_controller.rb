class Reports::CustomersController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!

  def index
    @date_range = params[:date_range] || '30_days'
    @start_date, @end_date = date_range_for(@date_range)
    
    # Customer metrics
    @total_customers = current_customers.count
    @new_customers = new_customers_in_period.count
    @previous_new_customers = previous_period_new_customers
    @customer_growth = calculate_percentage_change(@previous_new_customers, @new_customers)
    
    # Customer activity
    @active_customers = active_customers_in_period.count
    @previous_active_customers = previous_period_active_customers
    @activity_change = calculate_percentage_change(@previous_active_customers, @active_customers)
    
    # Customer value metrics
    @avg_customer_value = average_customer_value
    @previous_avg_value = previous_avg_customer_value
    @value_change = calculate_percentage_change(@previous_avg_value, @avg_customer_value)
    
    # Customer retention rate
    @returning_customers = returning_customers_count
    @retention_rate = @active_customers > 0 ? (@returning_customers.to_f / @active_customers * 100).round(1) : 0
    
    # Top customers by spending
    @top_customers = top_customers_by_spending
    
    # New customers over time
    @new_customers_trend = new_customers_trend_data
    
    # Customer distribution by location
    @customer_locations = customer_location_distribution
    
    # Customer visit frequency
    @visit_frequency = customer_visit_frequency
    
    # Customer lifetime value distribution
    @ltv_distribution = customer_ltv_distribution
  end

  private

  def current_customers
    @current_customers ||= Customer.where(shop_id: current_user.shop_id)
                                  .where(deleted_at: nil)
  end

  def new_customers_in_period
    current_customers.where(created_at: @start_date..@end_date)
  end

  def active_customers_in_period
    # Customers who had appointments in the period
    current_customers.joins(:appointments)
                    .where(appointments: { scheduled_at: @start_date..@end_date })
                    .distinct
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

  def previous_period_new_customers
    days_diff = (@end_date - @start_date).to_i
    prev_start = @start_date - days_diff.days
    prev_end = @start_date - 1.day
    
    current_customers.where(created_at: prev_start..prev_end).count
  end

  def previous_period_active_customers
    days_diff = (@end_date - @start_date).to_i
    prev_start = @start_date - days_diff.days
    prev_end = @start_date - 1.day
    
    current_customers.joins(:appointments)
                    .where(appointments: { scheduled_at: prev_start..prev_end })
                    .distinct
                    .count
  end

  def calculate_percentage_change(old_value, new_value)
    return 0 if old_value == 0 && new_value == 0
    return 100 if old_value == 0 && new_value > 0
    return -100 if old_value > 0 && new_value == 0
    
    ((new_value - old_value) / old_value * 100).round(1)
  end

  def average_customer_value
    total_revenue = active_customers_in_period.joins(:appointments)
                                             .where(appointments: { status: 'completed', updated_at: @start_date..@end_date })
                                             .sum('appointments.total_price_cents') / 100.0
    
    @active_customers > 0 ? (total_revenue / @active_customers).round(2) : 0
  end

  def previous_avg_customer_value
    days_diff = (@end_date - @start_date).to_i
    prev_start = @start_date - days_diff.days
    prev_end = @start_date - 1.day
    
    prev_active = current_customers.joins(:appointments)
                                  .where(appointments: { scheduled_at: prev_start..prev_end })
                                  .distinct
                                  .count
    
    prev_revenue = current_customers.joins(:appointments)
                                   .where(appointments: { status: 'completed', updated_at: prev_start..prev_end })
                                   .sum('appointments.total_price_cents') / 100.0
    
    prev_active > 0 ? (prev_revenue / prev_active).round(2) : 0
  end

  def returning_customers_count
    # Customers who had appointments before this period and also during this period
    customer_ids_in_period = active_customers_in_period.pluck(:id)
    
    current_customers.joins(:appointments)
                    .where(id: customer_ids_in_period)
                    .where(appointments: { scheduled_at: ...@start_date })
                    .distinct
                    .count
  end

  def top_customers_by_spending
    current_customers.joins(:appointments)
                    .where(appointments: { status: 'completed', updated_at: @start_date..@end_date })
                    .group('customers.id, customers.first_name, customers.last_name, customers.email')
                    .select('customers.*, SUM(appointments.total_price_cents) as total_spent, COUNT(appointments.id) as appointment_count')
                    .order('total_spent DESC')
                    .limit(10)
                    .map do |customer|
                      {
                        id: customer.id,
                        name: customer.full_name,
                        email: customer.email,
                        total_spent: customer.total_spent / 100.0,
                        appointment_count: customer.appointment_count,
                        avg_ticket: customer.total_spent / 100.0 / customer.appointment_count
                      }
                    end
  end

  def new_customers_trend_data
    # Daily new customers for the selected period
    new_customers_in_period.group("DATE(created_at)")
                          .count
                          .sort_by { |date, _| Date.parse(date) }
                          .to_h
  end

  def customer_location_distribution
    current_customers.where.not(city: [nil, ''])
                    .group(:city)
                    .count
                    .sort_by { |_, count| -count }
                    .first(10)
  end

  def customer_visit_frequency
    # Use SQL to calculate visit frequency buckets directly for better performance
    sql = <<-SQL
      SELECT 
        CASE 
          WHEN appointment_count = 1 THEN '1 visit'
          WHEN appointment_count BETWEEN 2 AND 3 THEN '2-3 visits'
          WHEN appointment_count BETWEEN 4 AND 5 THEN '4-5 visits'
          WHEN appointment_count BETWEEN 6 AND 10 THEN '6-10 visits'
          ELSE '10+ visits'
        END as frequency_bucket,
        COUNT(*) as customer_count
      FROM (
        SELECT customers.id, COUNT(appointments.id) as appointment_count
        FROM customers 
        INNER JOIN appointments ON appointments.customer_id = customers.id
        WHERE customers.shop_id = ? 
          AND customers.deleted_at IS NULL
          AND appointments.status = 'completed'
        GROUP BY customers.id
      ) visit_counts
      GROUP BY frequency_bucket
    SQL
    
    result = ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.send(:sanitize_sql_array, [sql, current_user.shop_id])
    )
    
    # Initialize buckets with 0 counts
    frequency_buckets = {
      '1 visit' => 0,
      '2-3 visits' => 0,
      '4-5 visits' => 0,
      '6-10 visits' => 0,
      '10+ visits' => 0
    }
    
    # Populate with actual counts
    result.each do |row|
      frequency_buckets[row['frequency_bucket']] = row['customer_count']
    end
    
    frequency_buckets
  end

  def customer_ltv_distribution
    # Use SQL to calculate LTV buckets directly for better performance
    sql = <<-SQL
      SELECT 
        CASE 
          WHEN total_spent_dollars <= 100 THEN '$0-$100'
          WHEN total_spent_dollars <= 500 THEN '$100-$500'
          WHEN total_spent_dollars <= 1000 THEN '$500-$1000'
          WHEN total_spent_dollars <= 2500 THEN '$1000-$2500'
          ELSE '$2500+'
        END as ltv_bucket,
        COUNT(*) as customer_count
      FROM (
        SELECT customers.id, SUM(appointments.total_price_cents) / 100.0 as total_spent_dollars
        FROM customers 
        INNER JOIN appointments ON appointments.customer_id = customers.id
        WHERE customers.shop_id = ? 
          AND customers.deleted_at IS NULL
          AND appointments.status = 'completed'
        GROUP BY customers.id
      ) customer_values
      GROUP BY ltv_bucket
    SQL
    
    result = ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.send(:sanitize_sql_array, [sql, current_user.shop_id])
    )
    
    # Initialize buckets with 0 counts
    ltv_buckets = {
      '$0-$100' => 0,
      '$100-$500' => 0,
      '$500-$1000' => 0,
      '$1000-$2500' => 0,
      '$2500+' => 0
    }
    
    # Populate with actual counts
    result.each do |row|
      ltv_buckets[row['ltv_bucket']] = row['customer_count']
    end
    
    ltv_buckets
  end
end