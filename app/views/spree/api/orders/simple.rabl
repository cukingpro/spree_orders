object @order

attributes *order_attributes

child(:group_by_date => :delivery) do 
	node() { |h| 
		node(:date_delivery) { h[:date_delivery] }
		child(h[:shipments] => :shipments) { extends "spree/api/shipments/simple"}
	}
end