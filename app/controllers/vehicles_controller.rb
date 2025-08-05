class VehiclesController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!
  before_action :set_vehicle, only: [:show, :edit, :update, :destroy]
  before_action :load_customers, only: [:new, :create, :edit, :update]

  def index
    @vehicles = Vehicle.includes(:customer)
    
    # Search functionality
    if params[:search].present?
      search_term = params[:search].downcase
      @vehicles = @vehicles.joins(:customer).where(
        "LOWER(vehicles.make) LIKE :search OR 
         LOWER(vehicles.model) LIKE :search OR 
         LOWER(vehicles.license_plate) LIKE :search OR
         LOWER(vehicles.vin) LIKE :search OR
         CAST(vehicles.year AS TEXT) LIKE :search OR
         LOWER(customers.first_name) LIKE :search OR
         LOWER(customers.last_name) LIKE :search",
        search: "%#{search_term}%"
      )
    end
    
    # Filter by customer
    if params[:customer_id].present?
      @vehicles = @vehicles.where(customer_id: params[:customer_id])
      @customer = Customer.find(params[:customer_id])
    end
    
    # Sorting
    sort_column = params[:sort] || 'make'
    sort_direction = params[:direction] == 'desc' ? 'desc' : 'asc'
    
    case sort_column
    when 'year'
      @vehicles = @vehicles.order(year: sort_direction)
    when 'make'
      @vehicles = @vehicles.order(make: sort_direction, model: sort_direction)
    when 'mileage'
      @vehicles = @vehicles.order(mileage: sort_direction)
    when 'customer'
      @vehicles = @vehicles.joins(:customer).order("customers.last_name #{sort_direction}, customers.first_name #{sort_direction}")
    else
      @vehicles = @vehicles.order(:make, :model, :year)
    end
    
    @pagy, @vehicles = pagy(@vehicles)
  end

  def show
    @appointments = @vehicle.appointments
      .includes(:services)
      .order(scheduled_at: :desc)
      .limit(10)
    
    @recent_services = AppointmentService
      .includes(:service, :appointment)
      .joins(appointment: :vehicle)
      .where(appointments: { vehicle_id: @vehicle.id, status: 'completed' })
      .order('appointments.scheduled_at DESC')
      .limit(10)
  end

  def new
    @vehicle = Vehicle.new
    @vehicle.customer_id = params[:customer_id] if params[:customer_id].present?
  end

  def create
    @vehicle = Vehicle.new(vehicle_params)
    
    if @vehicle.save
      redirect_to @vehicle, notice: 'Vehicle was successfully created.'
    else
      load_customers
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @vehicle.update(vehicle_params)
      redirect_to @vehicle, notice: 'Vehicle was successfully updated.'
    else
      load_customers
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    customer = @vehicle.customer
    @vehicle.destroy
    redirect_to vehicles_path(customer_id: customer.id), notice: 'Vehicle was successfully removed.'
  end

  private

  def set_vehicle
    @vehicle = Vehicle.find(params[:id])
  end

  def vehicle_params
    params.require(:vehicle).permit(:customer_id, :make, :model, :year, :color, :vin, :license_plate, :mileage, :notes)
  end

  def load_customers
    @customers = Customer.order(:last_name, :first_name)
  end
end