object false
child(@orders => :orders) do
  extends "spree/api/orders/show"
end
node(:count) { @orders.count }