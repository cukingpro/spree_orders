Spree::Core::Engine.routes.draw do
  namespace :api do
    resources :orders

    #Paypal
    post "orders/:id/cancel" => "/spree/api/orders#cancell"
    post '/paypal/:order_number', :to => "/spree/api/paypal#express", :as => :paypal_express
    get '/paypal/confirm', :to => "/spree/api/paypal#confirm", :as => :confirm_paypal
    get '/paypal/cancel', :to => "/spree/api/paypal#cancel", :as => :cancel_paypal
    get '/paypal/notify', :to => "/spree/api/paypal#notify", :as => :notify_paypal
    post 'paypall/add_fund', :to => "/spree/api/paypal#add_fund", :as => :add_fund_paypal
    get 'paypal/confirm_add_fund', :to => "/spree/api/paypal#confirm_add_fund", :as => :confirm_add_fund_paypal
    get 'paypal/cancel_add_fund', :to => "/spree/api/paypal#cancel_add_fund", :as => :cancel_add_fund_paypal

    # Bitpay
    post '/payment_method/bit_payments/authenticate'
    get '/spree_bitpay/invoice/new/:order_number', :to => "bitpay#pay_now", :as => :bitpay_pay_now
    get '/spree_bitpay/invoice/view', :to => "bitpay#view_invoice", :as => :bitpay_view_invoice
    get '/spree_bitpay/payment_sent', :to => "bitpay#payment_sent", :as => :bitpay_payment_sent
    get '/spree_bitpay/cancel', :to => "bitpay#cancel", :as => :bitpay_cancel
    get '/spree_bitpay/refresh', :to => "bitpay#refresh", :as => :bitpay_refresh
    get '/spree_bitpay/check', :to => "bitpay#check_payment_state", :as => :bitpay_check
    post '/spree_bitpay/notification', :to => "bitpay#notification", :as => :bitpay_notification
    post '/spree_bitpay/add_fund', :to => "bitpay#add_fund", :as => :bitpay_add_fund
    post '/spree_bitpay/add_fund_notification', :to => "bitpay#add_fund_notification", :as => :bitpay_add_fund_notification

    get '/user_history_orders/', :to => "/spree/api/orders#user_history_orders"
    get '/user_next_orders/', :to => "/spree/api/orders#user_next_orders"
    post '/shipments/split/', :to => "/spree/api/shipments#split"

  end
end
