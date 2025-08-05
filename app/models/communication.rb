class Communication < ApplicationRecord
  # Note: Gets shop context through customer association, no direct acts_as_tenant needed
  
  # Constants
  TYPES = %w[email sms].freeze
  STATUSES = %w[pending sent delivered failed].freeze
  DIRECTIONS = %w[inbound outbound].freeze
  
  # Associations
  belongs_to :customer
  belongs_to :user, optional: true
  
  # Validations
  validates :customer, presence: true
  validates :communication_type, presence: true, inclusion: { in: TYPES }
  validates :content, presence: true
  validates :status, inclusion: { in: STATUSES }, allow_nil: true
  validates :direction, presence: true, inclusion: { in: DIRECTIONS }
  
  # Scopes
  scope :emails, -> { where(communication_type: 'email') }
  scope :sms, -> { where(communication_type: 'sms') }
  scope :sent, -> { where(status: 'sent') }
  scope :delivered, -> { where(status: 'delivered') }
  scope :failed, -> { where(status: 'failed') }
  scope :inbound, -> { where(direction: 'inbound') }
  scope :outbound, -> { where(direction: 'outbound') }
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(communication_type: type) }
  scope :by_thread, ->(thread_id) { where(thread_id: thread_id) }
  
  # Callbacks
  before_validation :set_defaults
  after_create :mark_inbound_as_unread
  
  # Instance methods
  def sent?
    status == 'sent' || status == 'delivered'
  end
  
  def failed?
    status == 'failed'
  end
  
  def inbound?
    direction == 'inbound'
  end
  
  def outbound?
    direction == 'outbound'
  end
  
  def unread?
    read_at.nil?
  end
  
  def read?
    read_at.present?
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
  
  def mark_as_read!
    update!(read_at: Time.current) if unread?
  end
  
  def display_type
    communication_type.upcase
  end
  
  def display_direction
    direction.capitalize
  end
  
  def from_contact
    case communication_type
    when 'email'
      inbound? ? from_email : customer.email
    when 'sms'
      inbound? ? from_phone : customer.phone
    end
  end
  
  def to_contact
    case communication_type
    when 'email'
      outbound? ? to_email || customer.email : from_email
    when 'sms'
      outbound? ? to_phone || customer.phone : from_phone
    end
  end
  
  # Create a thread if this is the first message
  def ensure_thread_id
    if thread_id.blank?
      self.thread_id = "#{communication_type}_#{customer_id}_#{SecureRandom.hex(8)}"
    end
  end
  
  # Group messages by thread for conversation view
  def self.grouped_by_thread
    group_by(&:thread_id)
  end
  
  # Get conversation for a specific thread
  def conversation
    self.class.by_thread(thread_id).order(:created_at)
  end
  
  # Class methods for creating messages
  def self.create_outbound_email(customer:, user:, subject:, content:, thread_id: nil)
    create!(
      customer: customer,
      user: user,
      communication_type: 'email',
      direction: 'outbound',
      subject: subject,
      content: content,
      thread_id: thread_id || "email_#{customer.id}_#{SecureRandom.hex(8)}",
      to_email: customer.email,
      status: 'pending'
    )
  end
  
  def self.create_outbound_sms(customer:, user:, content:, thread_id: nil)
    create!(
      customer: customer,
      user: user,
      communication_type: 'sms',
      direction: 'outbound',
      content: content,
      thread_id: thread_id || "sms_#{customer.id}_#{SecureRandom.hex(8)}",
      to_phone: customer.phone,
      status: 'pending'
    )
  end
  
  def self.create_inbound_email(customer:, from_email:, subject:, content:, message_id:, thread_id: nil)
    create!(
      customer: customer,
      communication_type: 'email',
      direction: 'inbound',
      subject: subject,
      content: content,
      from_email: from_email,
      message_id: message_id,
      thread_id: thread_id || "email_#{customer.id}_#{SecureRandom.hex(8)}",
      status: 'delivered'
    )
  end
  
  def self.create_inbound_sms(customer:, from_phone:, content:, message_id:, thread_id: nil)
    create!(
      customer: customer,
      communication_type: 'sms',
      direction: 'inbound',
      content: content,
      from_phone: from_phone,
      message_id: message_id,
      thread_id: thread_id || "sms_#{customer.id}_#{SecureRandom.hex(8)}",
      status: 'delivered'
    )
  end
  
  private
  
  def set_defaults
    self.status ||= 'pending'
    self.direction ||= 'outbound'
    ensure_thread_id
  end
  
  def mark_inbound_as_unread
    if inbound? && read_at.nil?
      # This will be handled by notification system
    end
  end
end
