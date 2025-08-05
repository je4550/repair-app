class UsersController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy, :reset_password, :toggle_active]

  def index
    authorize User
    @users = policy_scope(User).includes(:location).order(:last_name, :first_name)
    
    # Filter by role if provided
    @users = @users.by_role(params[:role]) if params[:role].present? && User::ROLES.include?(params[:role])
    
    # Filter by location if provided (admin only)
    if params[:location_id].present? && current_user.admin?
      @users = @users.where(location_id: params[:location_id])
    end
    
    # Search functionality
    if params[:search].present?
      search_term = "%#{params[:search].downcase}%"
      @users = @users.where("LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR LOWER(email) LIKE ?", 
                           search_term, search_term, search_term)
    end
    
    # Load locations for filter dropdown (admin only)
    @locations = current_user.admin? ? Location.includes(:region).order('regions.name, locations.name') : []
    
    @pagy, @users = pagy(@users)
  end

  def show
    authorize @user
    @recent_activity = {
      customers_created: Customer.where(created_at: 30.days.ago..Time.current).count,
      appointments_handled: Appointment.where(updated_at: 30.days.ago..Time.current).count
    }
  end

  def new
    @user = User.new
    authorize @user
    @user.active = true
    load_available_locations
  end

  def create
    @user = User.new(user_params)
    authorize @user
    
    # Managers can only create users in their assigned location
    unless current_user.admin?
      @user.location = current_user.location
    end
    
    # Set a temporary password if not provided
    if params[:user][:password].blank?
      temp_password = generate_temp_password
      @user.password = temp_password
      @user.password_confirmation = temp_password
      send_welcome_email = true
    end
    
    if @user.save
      if send_welcome_email
        # TODO: Send welcome email with temp password
        flash[:notice] = "User created successfully. Temporary password: #{temp_password}"
      else
        flash[:notice] = "User created successfully."
      end
      redirect_to @user
    else
      load_available_locations
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @user
    load_available_locations
  end

  def update
    authorize @user
    # Remove password params if blank
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    
    # Managers cannot change location of users
    unless current_user.admin?
      params[:user].delete(:location_id)
    end
    
    if @user.update(user_params)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      load_available_locations
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user
    if @user == current_user
      redirect_to users_path, alert: "You cannot delete your own account."
      return
    end
    
    @user.update(active: false, deleted_at: Time.current)
    redirect_to users_path, notice: 'User was successfully deactivated.'
  end

  def reset_password
    authorize @user
    temp_password = generate_temp_password
    
    if @user.update(password: temp_password, password_confirmation: temp_password)
      # TODO: Send password reset email
      redirect_to @user, notice: "Password reset successfully. New password: #{temp_password}"
    else
      redirect_to @user, alert: 'Unable to reset password.'
    end
  end

  def toggle_active
    authorize @user
    @user.update(active: !@user.active?)
    redirect_to @user, notice: "User #{@user.active? ? 'activated' : 'deactivated'} successfully."
  end

  private

  def set_user
    @user = if current_user.admin?
              User.find(params[:id])
            else
              # Managers and other users can only access users in their assigned location
              User.where(location_id: current_user.location_id).find(params[:id])
            end
  rescue ActiveRecord::RecordNotFound
    redirect_to users_path, alert: 'User not found.'
  end

  def user_params
    params.require(:user).permit(policy(@user || User).permitted_attributes)
  end

  def load_available_locations
    @locations = if current_user.admin?
                   Location.includes(:region).order('regions.name, locations.name')
                 else
                   # Managers can only assign users to their own location
                   [current_user.location]
                 end
  end

  def generate_temp_password
    SecureRandom.alphanumeric(12)
  end
end