class UserPolicy < ApplicationPolicy
  def index?
    user.admin? || user.manager?
  end

  def show?
    user.admin? || user.manager? || user == record
  end

  def create?
    user.admin? || user.manager?
  end

  def new?
    create?
  end

  def update?
    if user.admin?
      true
    elsif user.manager?
      # Managers cannot edit admins
      !record.admin?
    elsif user == record
      # Users can edit their own profile (limited fields)
      true
    else
      false
    end
  end

  def edit?
    update?
  end

  def destroy?
    # Only admins can delete users, and users cannot delete themselves
    user.admin? && user != record
  end

  def reset_password?
    # Admins can reset anyone's password
    # Managers can reset non-admin passwords
    # Users cannot reset passwords (except through forgot password flow)
    if user.admin?
      user != record
    elsif user.manager?
      !record.admin? && user != record
    else
      false
    end
  end

  def toggle_active?
    # Same as destroy - admins only, cannot toggle own status
    user.admin? && user != record
  end

  class Scope < Scope
    def resolve
      if user.admin?
        # Admins see all users
        scope.all
      elsif user.manager?
        # Managers see users in their location only
        scope.where(location_id: user.location_id)
      else
        # Regular users only see themselves
        scope.where(id: user.id)
      end
    end
  end

  # Define which attributes can be edited by which roles
  def permitted_attributes
    if user.admin?
      [:first_name, :last_name, :email, :phone, :role, :location_id, :active, :password, :password_confirmation]
    elsif user.manager? && user != record
      [:first_name, :last_name, :email, :phone, :role, :active, :password, :password_confirmation]
    elsif user == record
      # Users editing their own profile
      [:first_name, :last_name, :phone, :password, :password_confirmation]
    else
      []
    end
  end
end