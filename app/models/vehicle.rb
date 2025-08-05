class Vehicle < ApplicationRecord
  acts_as_paranoid
  
  # Associations
  belongs_to :customer
  has_one :shop, through: :customer
  has_many :appointments, dependent: :destroy
  has_many :service_reminders, dependent: :destroy
  
  # Validations
  validates :customer, presence: true
  validates :make, presence: true
  validates :model, presence: true
  validates :year, presence: true, numericality: { greater_than: 1900, less_than_or_equal_to: Date.current.year + 1 }
  validates :vin, uniqueness: { case_sensitive: false }, allow_blank: true
  validates :license_plate, uniqueness: { case_sensitive: false, scope: :deleted_at }, allow_blank: true
  
  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :by_make, ->(make) { where(make: make) }
  scope :by_year, ->(year) { where(year: year) }
  scope :with_recent_service, -> { joins(:appointments).where(appointments: { scheduled_at: 6.months.ago.. }).distinct }
  
  # Instance methods
  def display_name
    "#{year} #{make} #{model}".strip
  end
  
  def full_display_name
    name = display_name
    name += " - #{license_plate}" if license_plate.present?
    name
  end
  
  def last_service_date
    appointments.completed.order(scheduled_at: :desc).first&.scheduled_at
  end
  
  def due_for_service?
    return true if last_service_date.nil?
    last_service_date < 3.months.ago
  end
  
  def decode_vin
    return {} if vin.blank?
    # VIN decoding logic would go here
    # For now, return empty hash
    {}
  end
  
  # Search
  def self.search(query)
    return all if query.blank?
    
    joins(:customer).where(
      "LOWER(vehicles.make) LIKE :query OR LOWER(vehicles.model) LIKE :query OR " +
      "vehicles.license_plate LIKE :query OR vehicles.vin LIKE :query OR " +
      "LOWER(customers.first_name) LIKE :query OR LOWER(customers.last_name) LIKE :query",
      query: "%#{query.downcase}%"
    )
  end
end
