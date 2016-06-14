object @variant

attributes :id, :name

node(:price) { |variant| variant.price }
child(:images => :images) { extends "spree/api/images/show" }
