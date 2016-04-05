Spree::Core::Engine.routes.draw do
  namespace :api do
    resources :orders
    post "orders/:id/cancel" => "/spree/api/orders#cancell"
    post '/paypal/:order_number', :to => "/spree/paypal#express", :as => :paypal_express
    get '/paypal/confirm', :to => "/spree/paypal#confirm", :as => :confirm_paypal
    get '/paypal/cancel', :to => "/spree/paypal#cancel", :as => :cancel_paypal
    get '/paypal/notify', :to => "/spree/paypal#notify", :as => :notify_paypal
  end
end
