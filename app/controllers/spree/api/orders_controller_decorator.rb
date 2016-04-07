Spree::Api::OrdersController.class_eval do

  before_action :find_order, except: [:create, :mine, :current, :index, :update, :user_history_orders]

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

  def user_history_orders
    @orders = Spree::Order.user_history_orders(current_api_user)
    respond_with(@orders, default_template: :index, status: 200)
  end

  def user_next_orders
    @orders = Spree::Order.user_next_orders(current_api_user)
    respond_with(@orders, default_template: :index, status: 200)
  end
  
end
