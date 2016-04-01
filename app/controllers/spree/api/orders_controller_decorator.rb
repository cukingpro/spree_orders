Spree::Api::OrdersController.class_eval do

  def create
    authorize! :create, Spree::Order
    order_user = if @current_user_roles.include?('admin') && order_params[:user_id]
      Spree.user_class.find(order_params[:user_id])
    else
      current_api_user
    end

    import_params = if @current_user_roles.include?("admin")
      params[:order].present? ? params[:order].permit! : {}
    else
      order_params
    end

    @order = Spree::Core::Importer::Order.import(order_user, import_params)
    @order.update(bill_address_id: params[:address_id], ship_address_id: params[:address_id])
    respond_with(@order, default_template: :show, status: 201)
  end

  def cancell
    if @order.destroy
      @status = [ { "messages" => "Your order was successfully canceled"}]
    else
      @status = [ { "messages" => "Your order was not successfully canceled"}]
    end
    render "spree/api/logger/log"
  end

end
