class AppointmentsController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!
  before_action :set_appointment, only: [:show, :edit, :update, :destroy, :confirm, :start, :complete, :cancel]
  before_action :load_customers_and_services, only: [:new, :create, :edit, :update]

  def index
    @appointments = Appointment.includes(:customer, :vehicle, :services)
    
    # Filter by status if provided
    @appointments = @appointments.by_status(params[:status]) if params[:status].present?
    
    # Filter by date range
    case params[:date_filter]
    when 'today'
      @appointments = @appointments.today
    when 'week'
      @appointments = @appointments.this_week
    when 'upcoming'
      @appointments = @appointments.upcoming
    when 'past'
      @appointments = @appointments.past
    else
      @appointments = @appointments.order(scheduled_at: :desc)
    end
    
    # Search
    if params[:search].present?
      @appointments = @appointments.joins(:customer, :vehicle).where(
        "LOWER(customers.first_name) LIKE :search OR LOWER(customers.last_name) LIKE :search OR 
         LOWER(vehicles.make) LIKE :search OR LOWER(vehicles.model) LIKE :search OR
         vehicles.license_plate LIKE :search",
        search: "%#{params[:search].downcase}%"
      )
    end
    
    @pagy, @appointments = pagy(@appointments)
  end

  def show
    @appointment_services = @appointment.appointment_services.includes(:service)
  end

  def new
    @appointment = Appointment.new
    @appointment.scheduled_at = params[:scheduled_at] if params[:scheduled_at].present?
    @appointment.customer_id = params[:customer_id] if params[:customer_id].present?
    @appointment.vehicle_id = params[:vehicle_id] if params[:vehicle_id].present?
  end

  def create
    @appointment = Appointment.new(appointment_params)
    
    if @appointment.save
      # Add selected services
      if params[:service_ids].present?
        params[:service_ids].each do |service_id|
          service = Service.find(service_id)
          quantity = params[:service_quantities]&.fetch(service_id, 1) || 1
          @appointment.add_service(service, quantity.to_i)
        end
        @appointment.calculate_total_price!
      end
      
      redirect_to @appointment, notice: 'Appointment was successfully created.'
    else
      load_customers_and_services
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @selected_service_ids = @appointment.service_ids
  end

  def update
    if @appointment.update(appointment_params)
      # Update services
      if params[:service_ids].present?
        @appointment.appointment_services.destroy_all
        params[:service_ids].each do |service_id|
          service = Service.find(service_id)
          quantity = params[:service_quantities]&.fetch(service_id, 1) || 1
          @appointment.add_service(service, quantity.to_i)
        end
        @appointment.calculate_total_price!
      end
      
      redirect_to @appointment, notice: 'Appointment was successfully updated.'
    else
      load_customers_and_services
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @appointment.destroy
    redirect_to appointments_url, notice: 'Appointment was successfully cancelled.'
  end

  # State transitions
  def confirm
    if @appointment.confirm!
      redirect_to @appointment, notice: 'Appointment confirmed.'
    else
      redirect_to @appointment, alert: 'Unable to confirm appointment.'
    end
  end

  def start
    if @appointment.start!
      redirect_to @appointment, notice: 'Appointment started.'
    else
      redirect_to @appointment, alert: 'Unable to start appointment.'
    end
  end

  def complete
    if @appointment.complete!
      redirect_to @appointment, notice: 'Appointment completed.'
    else
      redirect_to @appointment, alert: 'Unable to complete appointment.'
    end
  end

  def cancel
    if @appointment.cancel!
      redirect_to @appointment, notice: 'Appointment cancelled.'
    else
      redirect_to @appointment, alert: 'Unable to cancel appointment.'
    end
  end

  def customer_vehicles
    @vehicles = if params[:customer_id].present?
                  Vehicle.where(customer_id: params[:customer_id])
                else
                  Vehicle.none
                end
    
    render json: @vehicles.map { |v| { id: v.id, display_name: v.full_display_name } }
  end

  def check_availability
    date = params[:date].present? ? Date.parse(params[:date]) : Date.today
    time = params[:time].present? ? Time.parse("#{date} #{params[:time]}") : nil
    duration_minutes = params[:duration].to_i > 0 ? params[:duration].to_i : 60
    
    if time
      # Create a temporary appointment to check conflicts
      temp_appointment = Appointment.new(
        scheduled_at: time,
        customer_id: params[:customer_id],
        vehicle_id: params[:vehicle_id]
      )
      
      # Mock the duration
      temp_appointment.define_singleton_method(:duration_minutes) { duration_minutes }
      
      conflicts = temp_appointment.conflicting_appointments
      available = conflicts.empty?
      
      render json: {
        available: available,
        conflicts: conflicts.map { |c| {
          id: c.id,
          time: c.scheduled_at.strftime("%l:%M %p"),
          end_time: c.estimated_end_time.strftime("%l:%M %p"),
          customer: c.customer.full_name,
          vehicle: c.vehicle.full_display_name
        }}
      }
    else
      # Return all appointments for the day
      appointments = Appointment
        .includes(:customer, :vehicle)
        .where.not(status: [:cancelled, :no_show])
        .where(scheduled_at: date.beginning_of_day..date.end_of_day)
        .order(:scheduled_at)
      
      render json: {
        date: date,
        appointments: appointments.map { |a| {
          id: a.id,
          start: a.scheduled_at.strftime("%H:%M"),
          end: a.estimated_end_time.strftime("%H:%M"),
          title: "#{a.customer.full_name} - #{a.vehicle.full_display_name}",
          status: a.status
        }}
      }
    end
  end

  def calendar
    @date = params[:date].present? ? Date.parse(params[:date]) : Date.today
    @appointments = Appointment
      .includes(:customer, :vehicle)
      .where.not(status: [:cancelled, :no_show])
      .where(scheduled_at: @date.beginning_of_month..@date.end_of_month)
    
    # Group appointments by day
    @appointments_by_day = @appointments.group_by { |a| a.scheduled_at.to_date }
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def appointment_params
    permitted_params = params.require(:appointment).permit(:customer_id, :vehicle_id, :scheduled_at, :notes)
    
    # Handle separate date and time fields
    if params[:appointment][:scheduled_at_date].present? && params[:appointment][:scheduled_at_time].present?
      date = params[:appointment][:scheduled_at_date]
      time = params[:appointment][:scheduled_at_time]
      permitted_params[:scheduled_at] = "#{date} #{time}"
    end
    
    permitted_params
  end

  def load_customers_and_services
    @customers = Customer.includes(:vehicles).order(:last_name, :first_name)
    @services = Service.active.order(:name)
    @vehicles = if @appointment&.customer_id.present?
                  Vehicle.where(customer_id: @appointment.customer_id)
                else
                  Vehicle.none
                end
  end
end