module Spree
  module Api
    class PaypalController < StoreController
      skip_before_filter  :verify_authenticity_token
      def express
        order = current_order || raise(ActiveRecord::RecordNotFound)
        items = order.line_items.map(&method(:line_item))

        additional_adjustments = order.all_adjustments.additional
        tax_adjustments = additional_adjustments.tax
        shipping_adjustments = additional_adjustments.shipping

        additional_adjustments.eligible.each do |adjustment|
          # Because PayPal doesn't accept $0 items at all. See #10
          # https://cms.paypal.com/uk/cgi-bin/?cmd=_render-content&content_ID=developer/e_howto_api_ECCustomizing
          # "It can be a positive or negative value but not zero."
          next if adjustment.amount.zero?
          next if tax_adjustments.include?(adjustment) || shipping_adjustments.include?(adjustment)

          items << {
            Name: adjustment.label,
            Quantity: 1,
            Amount: {
              currencyID: order.currency,
              value: vnd_to_usd(adjustment.amount)
            }
          }
        end

        pp_request = provider.build_set_express_checkout(express_checkout_request_details(order, items))

        begin
          pp_response = provider.set_express_checkout(pp_request)
          if pp_response.success?
            @url = provider.express_checkout_url(pp_response, useraction: 'commit')
            render  status: 200, json: @url.to_json
            # redirect_to provider.express_checkout_url(pp_response, useraction: 'commit')
          else
            flash[:error] = Spree.t('flash.generic_error', scope: 'paypal', reasons: pp_response.errors.map(&:long_message).join(" "))
            redirect_to checkout_state_path(:payment)
          end
        rescue SocketError
          flash[:error] = Spree.t('flash.connection_failed', scope: 'paypal')
          redirect_to checkout_state_path(:payment)
        end
      end

      def confirm
        order = current_order || raise(ActiveRecord::RecordNotFound)
        order.payments.create!({
                                 source: Spree::PaypalExpressCheckout.create({
                                                                               token: params[:token],
                                                                               payer_id: params[:PayerID]
                                 }),
                                 amount: order.total,
                                 payment_method: payment_method
        })
        order.next
        if order.complete?
          flash.notice = Spree.t(:order_processed_successfully)
          flash[:order_completed] = true
          session[:order_id] = nil
          # redirect_to completion_route(order)
          # render  status: 200, json: "success".to_json
          redirect_to DOMAIN+"/confirm_order/reviewOrder"
        else
          redirect_to DOMAIN
          # render status: 200, json: "failed".to_json
          # redirect_to checkout_state_path(order.state)
        end
      end

      def cancel
        flash[:notice] = Spree.t('flash.cancel', scope: 'paypal')
        # order = current_order || raise(ActiveRecord::RecordNotFound)
        redirect_to DOMAIN
        # redirect_to checkout_state_path(order.state, paypal_cancel_token: params[:token])
      end

      def add_fund
        user = current_api_user
        amount = params[:amount].to_i

        pp_request = provider.build_set_express_checkout(add_fund_request_details(user, amount))

        begin
          pp_response = provider.set_express_checkout(pp_request)
          if pp_response.success?
            @url = provider.express_checkout_url(pp_response, useraction: 'commit')
            render  status: 200, json: @url.to_json
            # redirect_to provider.express_checkout_url(pp_response, useraction: 'commit')
          else
            flash[:error] = Spree.t('flash.generic_error', scope: 'paypal', reasons: pp_response.errors.map(&:long_message).join(" "))
            redirect_to checkout_state_path(:payment)
          end
        rescue SocketError
          flash[:error] = Spree.t('flash.connection_failed', scope: 'paypal')
          redirect_to checkout_state_path(:payment)
        end

        def confirm_add_fund
          user = current_api_user
          user.add_fund(params[:amount].to_i)
          user.save 
          redirect_to DOMAIN
        end

        def cancel_add_fund
          flash[:notice] = Spree.t('flash.cancel', scope: 'paypal')
          redirect_to DOMAIN
        end

      end



      private

      def line_item(item)
        {
          Name: item.product.name,
          Number: item.variant.sku,
          Quantity: item.quantity,
          Amount: {
            currencyID: "USD",
            value: vnd_to_usd(item.price)
          },
          ItemCategory: "Physical"
        }
      end

      def express_checkout_request_details order, items
        { SetExpressCheckoutRequestDetails: {
            InvoiceID: order.number,
            BuyerEmail: order.email,
            ReturnURL: api_confirm_paypal_url(payment_method_id: params[:payment_method_id], order_number: params[:order_number], utm_nooverride: 1),
            CancelURL:  api_cancel_paypal_url,
            SolutionType: payment_method.preferred_solution.present? ? payment_method.preferred_solution : "Mark",
            LandingPage: payment_method.preferred_landing_page.present? ? payment_method.preferred_landing_page : "Billing",
            cppheaderimage: payment_method.preferred_logourl.present? ? payment_method.preferred_logourl : "",
            NoShipping: 1,
            PaymentDetails: [payment_details(items)]
        }}
      end

      def payment_method
        Spree::PaymentMethod.find(params[:payment_method_id])
      end

      def provider
        payment_method.provider
      end

      def payment_details items
        # This retrieves the cost of shipping after promotions are applied
        # For example, if shippng costs $10, and is free with a promotion, shipment_sum is now $10
        shipment_sum = current_order.shipments.map(&:discounted_cost).sum

        # This calculates the item sum based upon what is in the order total, but not for shipping
        # or tax.  This is the easiest way to determine what the items should cost, as that
        # functionality doesn't currently exist in Spree core
        item_sum = current_order.total - shipment_sum - current_order.additional_tax_total

        if item_sum.zero?
          # Paypal does not support no items or a zero dollar ItemTotal
          # This results in the order summary being simply "Current purchase"
          {
            OrderTotal: {
              currencyID: current_order.currency,
              value: vnd_to_usd(current_order.total)
            }
          }
        else
          {
            OrderTotal: {
              currencyID: "USD",
              value: vnd_to_usd(current_order.total)
            },
            ItemTotal: {
              currencyID: "USD",
              value: vnd_to_usd(item_sum)
            },
            ShippingTotal: {
              currencyID: "USD",
              value: vnd_to_usd(shipment_sum),
            },
            TaxTotal: {
              currencyID: "USD",
              value: vnd_to_usd(current_order.additional_tax_total)
            },
            ShipToAddress: address_options,
            PaymentDetailsItem: items,
            ShippingMethod: "Shipping Method Name Goes Here",
            PaymentAction: "Sale"
          }
        end
      end

      def address_options
        return {} unless address_required?

        {
          Name: current_order.bill_address.try(:full_name),
          Street1: current_order.bill_address.address1,
          Street2: current_order.bill_address.address2,
          CityName: current_order.bill_address.city,
          Phone: current_order.bill_address.phone,
          StateOrProvince: current_order.bill_address.state_text,
          Country: current_order.bill_address.country.iso,
          PostalCode: current_order.bill_address.zipcode
        }
      end

      def completion_route(order)
        order_path(order)
      end

      def address_required?
        payment_method.preferred_solution.eql?('Sole')
      end

      def current_order
        Spree::Order.find_by(number: params[:order_number])
      end

      def vnd_to_usd(price)
        return BigDecimal.new(price/20000)
      end

      def add_fund_request_details(user, amount)
        { SetExpressCheckoutRequestDetails: {
            # InvoiceID: order.number,
            BuyerEmail: user.email,
            ReturnURL: api_confirm_add_fund_paypal_url(spree_api_key: user.spree_api_key, amount: amount, utm_nooverride: 1),
            CancelURL:  api_cancel_add_fund_paypal_url,
            SolutionType: payment_method.preferred_solution.present? ? payment_method.preferred_solution : "Mark",
            LandingPage: payment_method.preferred_landing_page.present? ? payment_method.preferred_landing_page : "Billing",
            cppheaderimage: payment_method.preferred_logourl.present? ? payment_method.preferred_logourl : "",
            NoShipping: 1,
            PaymentDetails: [add_fund_details(amount)]
        }}
      end

      def add_fund_details(amount)
        {
          OrderTotal: {
            currencyID: "USD",
            value: vnd_to_usd(amount)
          }
        }
      end

      def current_api_user
        Spree::User.find_by(spree_api_key: api_key.to_s)
      end

      def api_key
        request.headers["X-Spree-Token"] || params[:spree_api_key]
      end

    end
  end
end
