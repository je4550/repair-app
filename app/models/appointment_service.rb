class AppointmentService < ApplicationRecord
  # Money
  monetize :price_cents, allow_nil: false
  
  # Associations
  belongs_to :appointment
  belongs_to :service
  
  # Validations
  validates :appointment, presence: true
  validates :service, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # Callbacks
  before_validation :set_default_price
  after_save :update_appointment_total
  after_destroy :update_appointment_total
  
  # Instance methods
  def total_price
    Money.new(price_cents * quantity, price_currency)
  end
  
  def display_name
    "#{service.name} x#{quantity}"
  end
  
  private
  
  def set_default_price
    return if price.present?
    self.price = service&.price || 0
  end
  
  def update_appointment_total
    appointment.calculate_total_price! if appointment.completed?
  end
end
