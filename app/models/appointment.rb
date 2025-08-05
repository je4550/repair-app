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
  validate :no_scheduling_conflicts, if: :scheduled_at_changed?
  
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
  
  # Check for conflicts with other appointments
  def conflicts_with?(other_appointment)
    return false if other_appointment == self
    return false if other_appointment.cancelled? || other_appointment.no_show?
    
    # Calculate time ranges
    self_start = scheduled_at
    self_end = estimated_end_time
    other_start = other_appointment.scheduled_at
    other_end = other_appointment.estimated_end_time
    
    # Check for overlap
    (self_start < other_end) && (other_start < self_end)
  end
  
  # Get all conflicting appointments
  def conflicting_appointments
    return Appointment.none unless scheduled_at.present?
    
    shop = ActsAsTenant.current_tenant
    return Appointment.none unless shop
    
    # Find appointments that might conflict (within the same day)
    potential_conflicts = shop.appointments
      .where.not(id: id)
      .where.not(status: [:cancelled, :no_show])
      .where(scheduled_at: scheduled_at.beginning_of_day..scheduled_at.end_of_day)
    
    # Filter to actual conflicts
    potential_conflicts.select { |apt| conflicts_with?(apt) }
  end
  
  private
  
  def vehicle_belongs_to_customer
    return if vehicle.blank? || customer.blank?
    
    unless vehicle.customer_id == customer_id
      errors.add(:vehicle, "must belong to the selected customer")
    end
  end
  
  def no_scheduling_conflicts
    return unless scheduled_at.present?
    
    conflicts = conflicting_appointments
    if conflicts.any?
      conflict_times = conflicts.map { |c| c.scheduled_at.strftime("%l:%M %p") }.join(", ")
      errors.add(:scheduled_at, "conflicts with existing appointments at: #{conflict_times}")
    end
  end
end
