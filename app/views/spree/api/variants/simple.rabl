object @variant

attributes *variant_attributes

node(:display_price) { |p| p.display_price.to_s }

child(:images => :images) { extends "spree/api/v1/images/show" }
