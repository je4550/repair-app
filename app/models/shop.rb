class Shop < ApplicationRecord
  # New hierarchy associations
  has_many :regions, dependent: :destroy
  has_many :locations, through: :regions
  
  # Associations through locations
  has_many :users, through: :locations
  has_many :customers, through: :locations
  has_many :vehicles, through: :customers
  has_many :services, through: :locations
  has_many :appointments, through: :customers
  has_many :communications, through: :customers
  has_many :reviews, through: :customers
  has_many :service_reminders, through: :customers
  
  # Validations
  validates :name, presence: true
  validates :subdomain, presence: true, uniqueness: { case_sensitive: false },
            format: { with: /\A[a-z0-9-]+\z/, message: "can only contain lowercase letters, numbers, and hyphens" },
            exclusion: { in: %w[www admin api app mail email ftp ssh], message: "%{value} is reserved" }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :active, inclusion: { in: [true, false] }
  
  # Phone number validation
  validates :phone, phone: { possible: true, allow_blank: false }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  
  # Callbacks
  before_validation :normalize_subdomain
  after_create :create_default_region_and_location
  
  # Instance methods
  def full_address
    [address_line1, address_line2, "#{city}, #{state} #{zip}"].compact.reject(&:blank?).join("\n")
  end
  
  def deactivate!
    update!(active: false)
  end
  
  def activate!
    update!(active: true)
  end
  
  def total_customers
    customers.count
  end
  
  def total_vehicles
    vehicles.count
  end
  
  def total_appointments
    appointments.count
  end
  
  def monthly_revenue(date = Date.current)
    appointments
      .completed
      .where(scheduled_at: date.beginning_of_month..date.end_of_month)
      .sum(:total_price)
  end
  
  private
  
  def normalize_subdomain
    self.subdomain = subdomain&.downcase&.strip
  end
  
  def create_default_region_and_location
    # Create default region and location for new shops
    region = regions.create!(name: "Main Region")
    
    location = region.locations.create!(
      name: "Main Location",
      address_line1: address_line1,
      address_line2: address_line2,
      city: city,
      state: state,
      zip: zip,
      phone: phone,
      email: email,
      active: active
    )
    
    # Create default services for the location
    default_services = [
      { name: "Oil Change", description: "Standard oil change service", price_cents: 3999, duration_minutes: 30 },
      { name: "Tire Rotation", description: "Rotate all four tires", price_cents: 2500, duration_minutes: 20 },
      { name: "Brake Inspection", description: "Complete brake system inspection", price_cents: 0, duration_minutes: 15 },
      { name: "Battery Test", description: "Battery and charging system test", price_cents: 0, duration_minutes: 10 },
      { name: "Multi-Point Inspection", description: "Comprehensive vehicle inspection", price_cents: 0, duration_minutes: 30 }
    ]
    
    ActsAsTenant.with_tenant(self) do
      default_services.each do |service_attrs|
        location.services.create!(service_attrs)
      end
    end
  end
end
