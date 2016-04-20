object @shipment

attributes *shipment_attributes, :date_delivery
node(:time_frame) { |shipment| shipment.time_frame.name }

child :manifest => :manifest do
  child :variant => :variant do
    extends "spree/api/variants/simple"
  end
  node(:quantity) { |m| m.quantity }
end