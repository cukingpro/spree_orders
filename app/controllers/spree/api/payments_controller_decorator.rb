Spree::Api::PaymentsController.class_eval do

  def capture
  	current_api_user.balance -= @payment.amount
  	current_api_user.save
    perform_payment_action(:capture)
  end

end
