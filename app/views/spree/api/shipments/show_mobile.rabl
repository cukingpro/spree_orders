object @shipment

attributes *shipment_attributes, :date_delivery
node(:time_frame) { |shipment| shipment.time_frame.name }
child(:address) { extends "spree/api/addresses/show" }
child :manifest => :manifest do
  child :variant => :product do
    extends "spree/api/variants/show_mobile"
  end
  node(:quantity) { |m| m.quantity }
end