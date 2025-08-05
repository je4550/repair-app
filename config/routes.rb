Rails.application.routes.draw do
  # Health check available on all subdomains
  get "up" => "rails/health#show", as: :rails_health_check

  # Routes without subdomain constraint (main website)
  constraints subdomain: "" do
    root to: "pages#home"
    get "about", to: "pages#about"
    get "pricing", to: "pages#pricing"
    get "contact", to: "pages#contact"

    # Shop signup
    resources :shops, only: [ :new, :create ]
  end

  # Routes with subdomain constraint (tenant-specific)
  constraints subdomain: /.+/ do
    devise_for :users

    authenticated :user do
      root to: "dashboard#index", as: :authenticated_root
      get "switch_location", to: "dashboard#switch_location"
    end

    unauthenticated do
      root to: redirect("/users/sign_in"), as: :unauthenticated_root
    end

    resources :customers do
      resources :vehicles
      resources :appointments
      resources :communications
    end

    resources :communications do
      member do
        post :reply
        patch :mark_as_read
      end
      collection do
        patch :mark_all_as_read
      end
    end

    resources :vehicles
    resources :services do
      member do
        patch :toggle_active
      end
    end
    resources :appointments do
      member do
        patch :confirm
        patch :start
        patch :complete
        patch :cancel
      end
      collection do
        get :customer_vehicles
        get :check_availability
        get :calendar
      end
      resources :appointment_services
    end

    resources :reviews
    resources :service_reminders

    namespace :reports do
      get "revenue", to: "revenue#index"
      get "customers", to: "customers#index"
      get "services", to: "services#index"
    end

    namespace :settings do
      resource :shop, only: [ :edit, :update ]
      resources :users
    end
  end
end
