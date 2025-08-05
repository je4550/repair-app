class CommunicationsController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!
  before_action :set_communication, only: [:show, :mark_as_read]
  before_action :set_customer, only: [:new, :create]

  def index
    @communications = Communication.includes(:customer, :user).recent
    
    # Simple search functionality
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @communications = @communications.joins(:customer)
                                     .where("communications.content LIKE ? OR communications.subject LIKE ? OR customers.first_name LIKE ? OR customers.last_name LIKE ?", 
                                            search_term, search_term, search_term, search_term)
    end
    
    # Group by threads for conversation view - only get latest message per thread
    @grouped_communications = @communications.group(:thread_id)
                                           .select("communications.*, MAX(communications.created_at) as latest_message_time")
                                           .order("latest_message_time DESC")
                                           .limit(50)
                                           .group_by(&:thread_id)
    
    # Filter stats
    @unread_count = Communication.unread.count
    @total_count = Communication.count
    @email_count = Communication.emails.count
    @sms_count = Communication.sms.count
  end

  def show
    @communication.mark_as_read! if @communication.inbound? && @communication.unread?
    @conversation = @communication.conversation
    @reply = Communication.new(
      customer: @communication.customer,
      communication_type: @communication.communication_type,
      thread_id: @communication.thread_id,
      direction: 'outbound'
    )
  end

  def new
    @communication = Communication.new(
      customer: @customer,
      communication_type: params[:type] || 'email',
      direction: 'outbound'
    )
  end

  def create
    @communication = Communication.new(communication_params)
    @communication.user = current_user
    @communication.direction = 'outbound'
    
    if @communication.save
      # Send the message (this would integrate with email/SMS service)
      send_message(@communication)
      redirect_to @communication, notice: 'Message sent successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def reply
    @original = Communication.find(params[:id])
    @communication = Communication.new(
      customer: @original.customer,
      user: current_user,
      communication_type: @original.communication_type,
      thread_id: @original.thread_id,
      direction: 'outbound'
    )
    
    if @communication.update(reply_params)
      send_message(@communication)
      redirect_to @original, notice: 'Reply sent successfully.'
    else
      redirect_to @original, alert: 'Failed to send reply.'
    end
  end

  def mark_as_read
    @communication.mark_as_read!
    redirect_back(fallback_location: communications_path)
  end

  def mark_all_as_read
    Communication.unread.update_all(read_at: Time.current)
    redirect_to communications_path, notice: 'All messages marked as read.'
  end

  private

  def set_communication
    @communication = Communication.find(params[:id])
  end

  def set_customer
    @customer = Customer.find(params[:customer_id]) if params[:customer_id]
  end

  def communication_params
    params.require(:communication).permit(:customer_id, :communication_type, :subject, :content, :to_email, :to_phone)
  end

  def reply_params
    params.require(:communication).permit(:content, :subject)
  end

  def send_message(communication)
    case communication.communication_type
    when 'email'
      send_email(communication)
    when 'sms'
      send_sms(communication)
    end
  end

  def send_email(communication)
    # This would integrate with ActionMailer or email service
    # For now, just mark as sent
    communication.mark_as_sent!
  rescue => e
    communication.mark_as_failed!(e.message)
  end

  def send_sms(communication)
    # This would integrate with SMS service like Twilio
    # For now, just mark as sent
    communication.mark_as_sent!
  rescue => e
    communication.mark_as_failed!(e.message)
  end
end