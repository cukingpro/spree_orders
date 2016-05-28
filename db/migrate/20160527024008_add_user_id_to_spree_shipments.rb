class AddUserIdToSpreeShipments < ActiveRecord::Migration
  def change
  	add_column :spree_shipments, :user_id, :integer
  end
end
