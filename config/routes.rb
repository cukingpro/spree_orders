Spree::Core::Engine.routes.draw do
  namespace :api do
    resources :orders
    post "orders/:id/cancel" => "/spree/api/orders#cancell"
    post '/paypal/:order_number', :to => "/spree/api/paypal#express", :as => :paypal_express
    get '/paypal/confirm', :to => "/spree/api/paypal#confirm", :as => :confirm_paypal
    get '/paypal/cancel', :to => "/spree/api/paypal#cancel", :as => :cancel_paypal
    get '/paypal/notify', :to => "/spree/api/paypal#notify", :as => :notify_paypal

    post 'paypall/add_fund', :to => "/spree/api/paypal#add_fund", :as => :add_fund_paypal
    get 'paypal/confirm_add_fund', :to => "/spree/api/paypal#confirm_add_fund", :as => :confirm_add_fund_paypal
    get 'paypal/cancel_add_fund', :to => "/spree/api/paypal#cancel_add_fund", :as => :cancel_add_fund_paypal

    get '/user_history_orders/', :to => "/spree/api/orders#user_history_orders"
    get '/user_next_orders/', :to => "/spree/api/orders#user_next_orders"

    post '/shipments/split/', :to => "/spree/api/shipments#split"
    
  end
end
