class Communication < ApplicationRecord
  
  # Constants
  TYPES = %w[email sms].freeze
  STATUSES = %w[pending sent delivered failed].freeze
  
  # Associations
  belongs_to :customer
  
  # Validations
  validates :customer, presence: true
  validates :communication_type, presence: true, inclusion: { in: TYPES }
  validates :content, presence: true
  validates :status, inclusion: { in: STATUSES }, allow_nil: true
  
  # Scopes
  scope :emails, -> { where(communication_type: 'email') }
  scope :sms, -> { where(communication_type: 'sms') }
  scope :sent, -> { where(status: 'sent') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :failed, -> { where(status: 'failed') }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(communication_type: type) }
  
  # Callbacks
  before_validation :set_defaults
  
  # Instance methods
  def sent?
    status == 'sent' || status == 'delivered'
  end
  
  def failed?
    status == 'failed'
  end
  
  def mark_as_sent!
    update!(status: 'sent', sent_at: Time.current)
  end
  
  def mark_as_delivered!
    update!(status: 'delivered')
  end
  
  def mark_as_failed!(error_message = nil)
    if error_message
      update!(status: 'failed', content: content + "\n\nError: #{error_message}")
    else
      update!(status: 'failed')
    end
  end
  
  def display_type
    communication_type.upcase
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
  end
end
