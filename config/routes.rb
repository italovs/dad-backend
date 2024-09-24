Rails.application.routes.draw do
  get 'products/home', to: 'products#home'

  resources :order_products
  resources :orders
  resources :product_models
  resources :products

  devise_for :users, path: '', path_names: {
                                 sign_in: 'login',
                                 sign_out: 'logout',
                                 registration: 'signup'
                               },
                     controllers: {
                       sessions: 'users/sessions',
                       registrations: 'users/registrations'
                     }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "/categories", to: "products#categories", as: "product_categories"

  get "/aws-upload-link", to: "products#aws_upload_link", as: "aws_upload_link"

  # Defines the root path route ("/")
  # root "articles#index"
end
