Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  devise_for :admins, path: "admin/auth"

  namespace :admin do
    root "workshops#index"
    resources :workshops, only: %i[index show] do
      member do
        patch :approve
        patch :decline
        patch :suspend
      end
    end
    resources :users, only: %i[index show]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :workshop_management do
    resources :workshops, only: [:show] do
      resource :dashboard, only: [:show]
    end
  end

  resources :service_categories
  resources :workshops
  resources :my_workshops, only: [:index]

  root "dashboard#index"
end
