object @variant

attributes :id, :name

child(:images => :images) { extends "spree/api/images/show" }
