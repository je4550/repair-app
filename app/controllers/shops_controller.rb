class ShopsController < ApplicationController
  skip_before_action :set_tenant
  
  def new
    @shop = Shop.new
  end

  def create
    @shop = Shop.new(shop_params)
    
    if @shop.save
      # Create admin user for the shop
      user = User.create!(
        email: shop_params[:email],
        password: params[:password],
        password_confirmation: params[:password_confirmation],
        first_name: shop_params[:owner_name].split(' ').first,
        last_name: shop_params[:owner_name].split(' ').last,
        phone: shop_params[:phone],
        role: 'admin',
        shop: @shop
      )
      
      sign_in(user)
      redirect_to root_url(subdomain: @shop.subdomain), notice: 'Your shop has been created successfully!'
    else
      render :new
    end
  end
  
  private
  
  def shop_params
    params.require(:shop).permit(:name, :subdomain, :owner_name, :email, :phone, 
                                  :address_line1, :address_line2, :city, :state, :zip)
  end
end
