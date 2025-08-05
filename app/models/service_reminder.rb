class ServiceReminder < ApplicationRecord
  
  # Constants
  REMINDER_TYPES = %w[mileage time custom].freeze
  STATUSES = %w[pending sent completed cancelled].freeze
  
  # Associations
  belongs_to :customer
  belongs_to :vehicle
  belongs_to :service
  
  # Validations
  validates :customer, presence: true
  validates :vehicle, presence: true
  validates :service, presence: true
  validates :reminder_type, presence: true, inclusion: { in: REMINDER_TYPES }
  validates :scheduled_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :vehicle_belongs_to_customer
  
  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :sent, -> { where(status: 'sent') }
  scope :due, -> { pending.where("scheduled_date <= ?", Date.current) }
  scope :upcoming, -> { pending.where("scheduled_date > ?", Date.current).order(:scheduled_date) }
  scope :by_type, ->(type) { where(reminder_type: type) }
  
  # Callbacks
  before_validation :set_defaults
  
  # Instance methods
  def due?
    pending? && scheduled_date <= Date.current
  end
  
  def pending?
    status == 'pending'
  end
  
  def mark_as_sent!
    update!(status: 'sent', sent_at: Time.current)
  end
  
  def mark_as_completed!
    update!(status: 'completed')
  end
  
  def cancel!
    update!(status: 'cancelled')
  end
  
  def days_until_due
    (scheduled_date - Date.current).to_i
  end
  
  def overdue_days
    return 0 unless due?
    (Date.current - scheduled_date).to_i
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
  end
  
  def vehicle_belongs_to_customer
    return if vehicle.blank? || customer.blank?
    
    unless vehicle.customer_id == customer_id
      errors.add(:vehicle, "must belong to the selected customer")
    end
  end
end
