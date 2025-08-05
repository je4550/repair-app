class Location < ApplicationRecord
  belongs_to :region
  has_one :shop, through: :region
  
  # Direct associations
  has_many :users, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :services, dependent: :destroy
  
  # Associations through customers
  has_many :vehicles, through: :customers
  has_many :appointments, through: :customers
  has_many :communications, through: :customers
  has_many :reviews, through: :customers
  has_many :service_reminders, through: :customers
  
  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :region_id }
  validates :phone, phone: { possible: true, allow_blank: true }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :active, inclusion: { in: [true, false] }
  
  # Scopes
  scope :active, -> { where(active: true, deleted_at: nil) }
  scope :inactive, -> { where(active: false) }
  
  # Acts as tenant setup - inherit from region's shop
  def current_tenant
    region.shop
  end
  
  # Soft delete
  def destroy
    update(deleted_at: Time.current)
  end
  
  # Address methods
  def full_address
    [address_line1, address_line2, city_state_zip].compact.reject(&:blank?).join("\n")
  end
  
  def city_state_zip
    [city, state, zip].compact.reject(&:blank?).join(" ")
  end
  
  # Status methods
  def deactivate!
    update!(active: false)
  end
  
  def activate!
    update!(active: true)
  end
  
  # Metrics
  def total_customers
    customers.where(deleted_at: nil).count
  end
  
  def total_vehicles
    vehicles.count
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
  
  def active_customers_count
    customers.joins(:appointments)
             .where(appointments: { updated_at: 6.months.ago.. })
             .distinct
             .count
  end
end
