class CustomersController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  def index
    @customers = Customer.includes(:vehicles).order(created_at: :desc)
    @customers = @customers.search(params[:search]) if params[:search].present?
    @pagy, @customers = pagy(@customers)
  end

  def show
    @vehicles = @customer.vehicles.includes(:appointments)
    @recent_appointments = @customer.appointments.includes(:vehicle, :appointment_services).order(scheduled_at: :desc).limit(5)
  end

  def new
    @customer = Customer.new
    @customer.vehicles.build # Build one vehicle by default
  end

  def create
    @customer = Customer.new(customer_params)
    
    if @customer.save
      redirect_to @customer, notice: 'Customer was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @customer.update(customer_params)
      redirect_to @customer, notice: 'Customer was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @customer.destroy
    redirect_to customers_url, notice: 'Customer was successfully deleted.'
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:first_name, :last_name, :email, :phone, :address_line1, :address_line2, :city, :state, :zip, :notes,
      vehicles_attributes: [:id, :vin, :make, :model, :year, :mileage, :license_plate, :color, :notes, :_destroy])
  end
end
