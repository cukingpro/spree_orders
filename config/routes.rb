Spree::Core::Engine.routes.draw do
  namespace :api do
    resources :orders
    post "orders/:id/cancel" => "/spree/api/orders#cancell"
  end
end
