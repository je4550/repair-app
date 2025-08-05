class User < ApplicationRecord
  # Include tenant-safe loading for Devise
  include TenantSafeUser
  
  acts_as_tenant(:shop)
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
         
  # Associations
  belongs_to :shop
         
  # Constants
  ROLES = %w[admin manager technician receptionist].freeze
  
  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :phone, presence: true
  validates :active, inclusion: { in: [true, false] }
  
  # Phone number validation
  validates :phone, phone: { possible: true, allow_blank: false }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_role, ->(role) { where(role: role) }
  scope :admins, -> { by_role('admin') }
  scope :managers, -> { by_role('manager') }
  scope :technicians, -> { by_role('technician') }
  scope :receptionists, -> { by_role('receptionist') }
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end
  
  def display_name
    full_name.presence || email
  end
  
  def admin?
    role == 'admin'
  end
  
  def manager?
    role == 'manager'
  end
  
  def technician?
    role == 'technician'
  end
  
  def receptionist?
    role == 'receptionist'
  end
  
  def can_manage_appointments?
    admin? || manager? || receptionist?
  end
  
  def can_manage_customers?
    admin? || manager? || receptionist?
  end
  
  def can_manage_users?
    admin?
  end
  
  def can_view_reports?
    admin? || manager?
  end
end
