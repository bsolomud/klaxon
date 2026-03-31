Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  devise_for :admins, path: "admin/auth"

  namespace :admin do
    root "workshops#index"
    resources :workshops, only: %i[index show] do
      member do
        patch :transition
      end
    end
    resources :users, only: %i[index show]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :workshop_management do
    resources :workshops, only: [:show] do
      resource :dashboard, only: [:show]
      resources :service_requests, only: [:index, :show] do
        member do
          patch :accept
          patch :reject
          patch :start
        end
        resource :service_record, only: [:new, :create]
      end
      resources :queues, only: [:index, :show] do
        collection do
          patch :open
        end
        member do
          patch :pause
          patch :close
        end
        resources :queue_entries, only: [] do
          member do
            patch :call
            patch :serve
            patch :complete
            patch :no_show
          end
        end
      end
    end
  end

  resources :cars
  resources :queue_entries, only: [:show, :create]
  resources :service_requests, only: [:index, :show, :new, :create]
  resources :car_transfers, only: [:new, :create, :show], param: :token do
    member do
      patch :approve
      patch :reject
      patch :cancel
    end
  end
  resources :service_categories
  resources :workshops
  resources :my_workshops, only: [:index]

  root "dashboard#index"
end
