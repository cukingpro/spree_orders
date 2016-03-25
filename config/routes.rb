Spree::Core::Engine.routes.draw do
  namespace :api do
    resources :orders
  end
end
