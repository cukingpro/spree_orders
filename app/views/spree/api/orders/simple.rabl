object @order

attributes *order_attributes

child :shipments => :shipments do
  extends "spree/api/shipments/simple"
end