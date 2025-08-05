class Appointment < ApplicationRecord
  include AASM
  acts_as_paranoid
  
  # Money
  monetize :total_price_cents, allow_nil: true
  
  # Associations
  belongs_to :customer
  belongs_to :vehicle
  has_many :appointment_services, dependent: :destroy
  has_many :services, through: :appointment_services
  has_one :review, dependent: :destroy
  
  # Validations
  validates :customer, presence: true
  validates :vehicle, presence: true
  validates :scheduled_at, presence: true
  validates :status, presence: true
  validate :vehicle_belongs_to_customer
  
  # State machine for appointment status
  aasm column: :status do
    state :scheduled, initial: true
    state :confirmed
    state :in_progress
    state :completed
    state :cancelled
    state :no_show
    
    event :confirm do
      transitions from: :scheduled, to: :confirmed
    end
    
    event :start do
      transitions from: [:scheduled, :confirmed], to: :in_progress
    end
    
    event :complete do
      transitions from: :in_progress, to: :completed
      after do
        calculate_total_price!
      end
    end
    
    event :cancel do
      transitions from: [:scheduled, :confirmed], to: :cancelled
    end
    
    event :mark_no_show do
      transitions from: [:scheduled, :confirmed], to: :no_show
    end
  end
  
  # Scopes
  scope :upcoming, -> { where("scheduled_at >= ?", Time.current).order(:scheduled_at) }
  scope :past, -> { where("scheduled_at < ?", Time.current).order(scheduled_at: :desc) }
  scope :today, -> { where(scheduled_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week, -> { where(scheduled_at: Time.current.beginning_of_week..Time.current.end_of_week) }
  scope :by_status, ->(status) { where(status: status) }
  
  # Instance methods
  def display_time
    scheduled_at.strftime("%B %d, %Y at %l:%M %p")
  end
  
  def duration_minutes
    appointment_services.joins(:service).sum("services.duration_minutes * appointment_services.quantity")
  end
  
  def estimated_end_time
    scheduled_at + duration_minutes.minutes
  end
  
  def calculate_total_price!
    self.total_price_cents = appointment_services.sum(:price_cents)
    save!
  end
  
  def add_service(service, quantity = 1, custom_price = nil)
    price = custom_price || service.price
    appointment_services.create!(
      service: service,
      quantity: quantity,
      price: price
    )
  end
  
  def overdue?
    scheduled? && scheduled_at < Time.current
  end
  
  private
  
  def vehicle_belongs_to_customer
    return if vehicle.blank? || customer.blank?
    
    unless vehicle.customer_id == customer_id
      errors.add(:vehicle, "must belong to the selected customer")
    end
  end
end
