Spree::Order.class_eval do
	# clear_validators!
	# remove_checkout_step :delivery
  
  def complete!
  	self.state = "complete"
  	self.completed_at = Time.current
  	self.save
  end

  def self.user_history_orders(user)
  	user.orders.where(shipment_state: "shipped")
  end

  def self.user_next_orders(user)
    user.orders.where.not(shipment_state: "shipped")
  end

  def group_by_date
    self.shipments.group_by{ |s| s[:date_delivery]}
  end
end
