module Spree
  module Api
    class BitpayController < StoreController
      skip_before_filter :verify_authenticity_token
      # Generates Bitpay Invoice and returns iframe view
      #
      def pay_now
        order = current_order || raise(ActiveRecord::RecordNotFound)
        session[:order_number] = current_order.number
        invoice = order.place_bitpay_order(notificationURL: api_bitpay_notification_url , redirectURL: DOMAIN+"/confirm_order/reviewOrder")
        @invoice_iframe_url = "#{invoice['url']}"
        render json: @invoice_iframe_url.to_json
      end

      # View Invoice with specific ID
      #
      def view_invoice
        invoice = BitPayInvoice.find(params[:source_id]).find_invoice
        redirect_to (invoice["url"] + '&view=iframe')
      end

      def check_payment_state
        invoice = BitPayInvoice.where(invoice_id: params[:invoice_id]).first
        pm = PaymentMethod.find(invoice.payment_method_id)
        status = pm.scan_the_server(invoice.invoice_id)
        render json: status
      end

      def cancel

        order = current_order || raise(ActiveRecord::RecordNotFound)
        order.cancel_bitpay_payment
        redirect_to edit_order_url(order, state: 'payment'), :notice => Spree.t(:order_canceled)

      end

      # Fires on receipt of payment received window message
      #
      def payment_sent
        order_number = session[:order_number]
        session[:order_number] = nil
        order = Spree::Order.find_by_number(order_number) || raise(ActiveRecord::RecordNotFound)
        redirect_to spree.order_path(order), :notice => Spree.t(:order_processed_successfully)
      end

      ## Handle IPN from Bitpay server
      # Receives incoming IPN message and retrieves official BitPay invoice for processing
      #
      def notification

        begin
          posData = JSON.parse(params["posData"])

          order_id = posData["orderID"]
          payment_id = posData["paymentID"]

          order = Spree::Order.find_by_number(order_id) || raise(ActiveRecord::RecordNotFound)
          begin
            order.process_bitpay_ipn payment_id
            head :ok
          rescue => exception
            logger.debug exception
            head :uprocessable_entity
          end
        rescue => error
          logger.error "Spree_Bitpay:  Unprocessable notification received from #{request.remote_ip}: #{params.inspect}"
          head :unprocessable_entity
        end
      end

      # Reprocess Invoice and update order status
      #
      def refresh
        payment = Spree::Payment.find(params[:payment])  # Retrieve payment by ID
        old_state = payment.state
        payment.process_bitpay_ipn
        new_state = payment.reload.state
        notice = (new_state == old_state) ? Spree.t(:bitpay_payment_not_updated) : (Spree.t(:bitpay_payment_updated) + new_state.titlecase)
        redirect_to (request.referrer || root_path), notice: notice
      end

      # Add fund to balance
      # 
      def add_fund
        invoice = Spree::PaymentMethod::BitPayment.first.create_invoice(add_fund_params)
        @invoice_url = "#{invoice['url']}"
        render json: @invoice_url.to_json
      end

      def add_fund_notification
        posData = JSON.parse(params["posData"])
        user = Spree::User.find(posData["user_id"].to_i)
        user.add_fund(posData["price"].to_i)
        head :ok if user.save
      end

      #####
      def current_api_user
        Spree::User.find_by(spree_api_key: api_key.to_s)
      end

      def api_key
        request.headers["X-Spree-Token"] || params[:spree_api_key]
      end

      def current_order
        Spree::Order.find_by(number: params[:order_number])
      end

      def add_fund_params
        {
          price: params[:amount],
          currency: "VND",
          notificationURL: api_bitpay_add_fund_notification_url,
          redirectURL: DOMAIN,
          posData: posDataJson,
          fullNotifications: true
        }
      end

      def posDataJson
        {
          user_id: current_api_user.id,
          price: params[:amount]
        }.to_json
      end

    end
  end
end
