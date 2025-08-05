class Region < ApplicationRecord
  belongs_to :shop
  has_many :locations, dependent: :destroy
  
  # Associations through locations
  has_many :users, through: :locations
  has_many :customers, through: :locations
  has_many :services, through: :locations
  has_many :appointments, through: :customers
  has_many :vehicles, through: :customers
  has_many :communications, through: :customers
  
  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :shop_id }
  
  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  
  # Acts as tenant setup
  acts_as_tenant :shop
  
  # Soft delete
  def destroy
    update(deleted_at: Time.current)
  end
  
  def active_locations
    locations.where(active: true, deleted_at: nil)
  end
  
  def total_customers
    customers.where(deleted_at: nil).count
  end
  
  def total_appointments
    appointments.count
  end
  
  def monthly_revenue(date = Date.current)
    appointments
      .joins(:appointment_services)
      .where(status: 'completed')
      .where(updated_at: date.beginning_of_month..date.end_of_month)
      .sum('appointment_services.price_cents') / 100.0
  end
end
