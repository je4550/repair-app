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
  
  # Nested attributes
  accepts_nested_attributes_for :vehicles, reject_if: proc { |attributes| attributes.all? { |key, value| key == '_destroy' || value.blank? } }, allow_destroy: true
  
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
    appointments.completed.sum(:total_price_cents) / 100.0
  end
  
  def vehicle_count
    vehicles.count
  end
  
  # Search
  def self.search(query)
    return all if query.blank?
    
    # Clean and prepare the query
    search_term = query.strip.downcase
    
    # Split the query into words for better fuzzy matching
    words = search_term.split(/\s+/)
    
    # Build conditions for each word
    conditions = []
    values = {}
    
    words.each_with_index do |word, index|
      word_key = "word#{index}".to_sym
      values[word_key] = "%#{word}%"
      
      # Search across multiple fields for each word
      conditions << "(LOWER(first_name) LIKE :#{word_key} OR 
                      LOWER(last_name) LIKE :#{word_key} OR 
                      LOWER(email) LIKE :#{word_key} OR 
                      phone LIKE :#{word_key} OR
                      LOWER(COALESCE(address_line1, '')) LIKE :#{word_key} OR
                      LOWER(COALESCE(city, '')) LIKE :#{word_key})"
    end
    
    # Also search for the full term (in case it's a full name)
    values[:full_term] = "%#{search_term}%"
    full_name_condition = "LOWER(first_name || ' ' || last_name) LIKE :full_term"
    
    # Combine all conditions
    where("(#{conditions.join(' AND ')}) OR #{full_name_condition}", values)
  end
end
