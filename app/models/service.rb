class Service < ApplicationRecord
  acts_as_paranoid
  
  # Associations
  belongs_to :location
  has_one :region, through: :location
  has_one :shop, through: :region
  
  # Acts as tenant - use shop through location
  def current_tenant
    location.region.shop
  end
  
  # Money
  monetize :price_cents, allow_nil: false
  
  # Associations
  has_many :appointment_services, dependent: :restrict_with_error
  has_many :appointments, through: :appointment_services
  has_many :service_reminders, dependent: :destroy
  
  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: :location_id }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_minutes, presence: true, numericality: { greater_than: 0 }
  validates :active, inclusion: { in: [true, false] }
  
  # Scopes
  scope :active, -> { where(active: true, deleted_at: nil) }
  scope :inactive, -> { where(active: false) }
  scope :by_name, -> { order(:name) }
  scope :popular, -> { 
    joins(:appointment_services)
      .group(:id)
      .order("COUNT(appointment_services.id) DESC") 
  }
  
  # Callbacks
  before_validation :set_defaults
  
  # Instance methods
  def display_price
    price.format
  end
  
  def duration_in_hours
    duration_minutes / 60.0
  end
  
  def formatted_duration
    hours = duration_minutes / 60
    minutes = duration_minutes % 60
    
    if hours > 0 && minutes > 0
      "#{hours}h #{minutes}m"
    elsif hours > 0
      "#{hours}h"
    else
      "#{minutes}m"
    end
  end
  
  def times_used
    appointment_services.count
  end
  
  def revenue_generated
    appointment_services.sum(:price)
  end
  
  # Search
  def self.search(query)
    return all if query.blank?
    
    where("LOWER(name) LIKE :query OR LOWER(description) LIKE :query",
          query: "%#{query.downcase}%")
  end
  
  private
  
  def set_defaults
    self.active = true if active.nil?
  end
end
