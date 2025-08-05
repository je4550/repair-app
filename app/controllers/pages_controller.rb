class PagesController < ApplicationController
  skip_before_action :set_tenant
  
  def home
  end

  def about
  end

  def pricing
  end

  def contact
  end
end
