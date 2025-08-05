class Customer < ApplicationRecord
  acts_as_tenant(:shop)
  acts_as_paranoid
  
  # Associations
  belongs_to :shop
  has_many :vehicles, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :communications, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :service_reminders, dependent: :destroy
  
  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :zip, format: { with: /\A\d{5}(-\d{4})?\z/, message: "should be in the format 12345 or 12345-6789" }, allow_blank: true
  
  # Phone number validation
  validates :phone, phone: { possible: true, allow_blank: false }
  
  # Scopes
  scope :active, -> { where(deleted_at: nil) }
  scope :with_vehicles, -> { includes(:vehicles) }
  scope :with_recent_appointments, -> { includes(appointments: :appointment_services).where(appointments: { scheduled_at: 1.year.ago.. }) }
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def full_address
    [address_line1, address_line2, "#{city}, #{state} #{zip}"].compact.reject(&:blank?).join("\n")
  end
  
  def last_visit
    appointments.completed.order(scheduled_at: :desc).first&.scheduled_at
  end
  
  def total_spent
    appointments.completed.sum(:total_price)
  end
  
  def vehicle_count
    vehicles.count
  end
  
  # Search
  def self.search(query)
    return all if query.blank?
    
    where("LOWER(first_name) LIKE :query OR LOWER(last_name) LIKE :query OR LOWER(email) LIKE :query OR phone LIKE :query",
          query: "%#{query.downcase}%")
  end
end
