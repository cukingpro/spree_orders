object @order

attributes *order_attributes

child :billing_address => :bill_address do
  extends "spree/api/addresses/show"
end

child :shipping_address => :ship_address do
  extends "spree/api/addresses/show"
end

child(:group_by_date => :delivery) do 
	node() { |h| 
		node(:date_delivery) { h[:date_delivery] }
		child(h[:shipments] => :shipments) { extends "spree/api/shipments/simple"}
	}
end