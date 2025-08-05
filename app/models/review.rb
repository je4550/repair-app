class Review < ApplicationRecord
  
  # Constants
  SOURCES = %w[website google yelp facebook internal].freeze
  
  # Associations
  belongs_to :customer
  belongs_to :appointment
  
  # Validations
  validates :customer, presence: true
  validates :appointment, presence: true
  validates :rating, presence: true, numericality: { in: 1..5 }
  validates :source, inclusion: { in: SOURCES }, allow_nil: true
  validates :appointment_id, uniqueness: { scope: :customer_id, message: "already has a review" }
  
  # Scopes
  scope :positive, -> { where("rating >= ?", 4) }
  scope :negative, -> { where("rating <= ?", 2) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_source, ->(source) { where(source: source) }
  scope :with_comments, -> { where.not(comment: [nil, '']) }
  
  # Callbacks
  before_validation :set_defaults
  after_create :send_thank_you_communication
  
  # Instance methods
  def positive?
    rating >= 4
  end
  
  def negative?
    rating <= 2
  end
  
  def display_rating
    "⭐" * rating
  end
  
  def display_source
    source&.capitalize || "Unknown"
  end
  
  private
  
  def set_defaults
    self.review_date ||= Time.current
    self.source ||= 'internal'
  end
  
  def send_thank_you_communication
    # This would trigger a background job to send thank you email/SMS
    # ReviewThankYouJob.perform_later(self)
  end
end
