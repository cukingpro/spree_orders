object @shipment

attributes *shipment_attributes, :date_delivery
node(:time_frame) { |shipment| shipment.time_frame.name }
node(:amount) { |shipment| shipment.amount }
node(:payment_method) { |shipment| shipment.order.payments.first.payment_method.name }
child(:order => :user) do 
	glue(:user) { extends "spree/api/users/show_mobile" }
end
child(:address) { extends "spree/api/addresses/show" }
child :manifest => :manifest do
  child :variant => :product do
    extends "spree/api/variants/show_mobile"
  end
  node(:quantity) { |m| m.quantity }
end