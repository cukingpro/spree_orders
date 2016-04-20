object false
child(@orders => :orders) do
  extends "spree/api/orders/simple"
end
node(:count) { @orders.count }