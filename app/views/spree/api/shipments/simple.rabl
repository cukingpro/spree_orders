object @shipment

attributes *shipment_attributes, :date_delivery
child(:time_frame) { attributes :id, :name }

child :manifest => :manifest do
  child :variant => :variant do
    extends "spree/api/variants/simple"
  end
  node(:quantity) { |m| m.quantity }
end