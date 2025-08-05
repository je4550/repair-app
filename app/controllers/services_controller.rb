class ServicesController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!
  before_action :set_service, only: [:show, :edit, :update, :destroy, :toggle_active]

  def index
    @services = Service.where(location_id: current_location.id)
    
    # Search functionality
    if params[:search].present?
      search_term = params[:search].downcase
      @services = @services.where(
        "LOWER(name) LIKE :search OR LOWER(description) LIKE :search",
        search: "%#{search_term}%"
      )
    end
    
    # Filter by status
    case params[:status]
    when 'active'
      @services = @services.active
    when 'inactive'
      @services = @services.inactive
    else
      # Show all by default
    end
    
    # Sorting
    sort_column = params[:sort] || 'name'
    sort_direction = params[:direction] == 'desc' ? 'desc' : 'asc'
    
    case sort_column
    when 'name'
      @services = @services.order(name: sort_direction)
    when 'price'
      @services = @services.order(price_cents: sort_direction)
    when 'duration'
      @services = @services.order(duration_minutes: sort_direction)
    when 'active'
      @services = @services.order(active: sort_direction)
    else
      @services = @services.order(:name)
    end
    
    @pagy, @services = pagy(@services)
  end

  def show
    @recent_appointments = @service.appointments
      .includes(:customer, :vehicle)
      .order(scheduled_at: :desc)
      .limit(10)
    
    @total_revenue = @service.appointment_services.sum(:price_cents) / 100.0
    @times_used = @service.appointment_services.count
  end

  def new
    @service = Service.new
    @service.active = true
  end

  def create
    @service = Service.new(service_params)
    @service.location = current_location
    
    if @service.save
      redirect_to @service, notice: 'Service was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @service.update(service_params)
      redirect_to @service, notice: 'Service was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @service.appointment_services.exists?
      # Don't delete services that have been used, just deactivate them
      @service.update(active: false)
      redirect_to services_url, notice: 'Service was deactivated because it has been used in appointments.'
    else
      @service.destroy
      redirect_to services_url, notice: 'Service was successfully deleted.'
    end
  end
  
  def toggle_active
    @service.update(active: !@service.active)
    status = @service.active? ? 'activated' : 'deactivated'
    redirect_to services_url, notice: "Service was successfully #{status}."
  end

  private

  def set_service
    @service = Service.where(location_id: current_location.id).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to services_path, alert: 'Service not found at this location.'
  end

  def service_params
    params.require(:service).permit(:name, :description, :price, :duration_minutes, :active)
  end
end