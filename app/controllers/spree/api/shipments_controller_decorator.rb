Spree::Api::ShipmentsController.class_eval do
	
  def split
    order = Spree::Order.find_by!(number: params[:order_number])
    original_shipment = Spree::Shipment.friendly.find(params[:original_shipment_number])
    # authorize! :read, @order
    # authorize! :create, Shipment

    shipments = params[:shipments]
    shipments.each do |sm|
    	shipment = order.shipments.create(stock_location_id: 1, date_delivery: sm[:date_delivery].to_date, time_frame_id: sm[:time_frame_id].to_i)

    	line_items = sm[:line_items]
    	line_items.each do |li|
    		variant = Spree::Variant.find(li[:variant_id].to_i)
    		quantity = li[:quantity].to_i
    		# order.contents.add(variant, quantity, {shipment: shipment})
    		original_shipment.transfer_to_shipment(variant, quantity, shipment)
            shipment.address = original_shipment.address

    	end
    end
    original_shipment.destroy!
    render json: {success: true, message: Spree.t(:shipment_transfer_success)}, status: 201
  end

  def show
    @shipment = Spree::Shipment.find(params[:id])
    render "spree/api/shipments/show_mobile"
  end

  def available_shipments
    @shipments = Spree::Shipment.available_shipments
    render "spree/api/shipments/index_mobile"
  end

  

end
