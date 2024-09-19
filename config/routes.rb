Rails.application.routes.draw do
  resources :order_products
  resources :orders
  resources :product_models
  resources :products
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
