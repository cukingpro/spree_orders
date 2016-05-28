Spree::Shipment.class_eval do

  def self.available_shipments
    Spree::Shipment.where(state: "ready", user_id: nil)
  end

  def self.user_history_shipments(user)
    Spree::Shipment.where(user_id: user.id, state: "shipped")
  end

  def self.user_next_shipments(user)
    Spree::Shipment.where(user_id: user.id, state: "ready")
  end
	
end
