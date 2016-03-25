Spree::Order.class_eval do
	# clear_validators!
	# remove_checkout_step :delivery
  
  def complete!
  	self.state = "complete"
  	self.completed_at = Time.current
  	self.save
  end
end
