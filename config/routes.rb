Spree::Core::Engine.routes.draw do
  namespace :api do
    resources :orders
    post "orders/:id/cancel" => "/spree/api/orders#cancell"
    post '/paypal/:order_number', :to => "/spree/paypal#express", :as => :paypal_express
    get '/paypal/confirm', :to => "/spree/paypal#confirm", :as => :confirm_paypal
    get '/paypal/cancel', :to => "/spree/paypal#cancel", :as => :cancel_paypal
    get '/paypal/notify', :to => "/spree/paypal#notify", :as => :notify_paypal

    get '/user_history_orders/', :to => "/spree/api/orders#user_history_orders"
    get '/user_next_orders/', :to => "/spree/api/orders#user_next_orders"
    
  end
end
