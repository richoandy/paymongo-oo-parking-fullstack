Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    resources :parking_lots, only: [:create, :show] do
      post :park, to: "parking#park"
      post :unpark, to: "parking#unpark"
      get "vehicle/:vehicle_identifier/fee", to: "parking#vehicle_fee", as: :vehicle_fee
    end
  end
end
