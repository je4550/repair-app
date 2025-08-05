class DashboardController < ApplicationController
  layout 'tenant'
  before_action :authenticate_user!
  
  def index
  end
end
