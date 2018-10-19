module Erp
  module Qdeliveries
    module Backend
      class PurchasesController < Erp::Backend::BackendController

        def purchases_orders
          if Erp::Core.available?("ortho_k")
            authorize! :inventory_qdeliveries_orders_purchase_orders, nil
          end
        end

        # POST /orders/list
        def purchases_orders_listing
          if Erp::Core.available?("ortho_k")
            authorize! :inventory_qdeliveries_orders_purchase_orders, nil
          end
          
          @orders = Erp::Orders::Order.purchase_orders.search(params).paginate(:page => params[:page], :per_page => 50)

          if params.to_unsafe_hash[:global_filter].present? and params.to_unsafe_hash[:global_filter][:order_from_date].present?
            @orders = @orders.where('order_date >= ?', params.to_unsafe_hash[:global_filter][:order_from_date].to_date.beginning_of_day)
          end

          if params.to_unsafe_hash[:global_filter].present? and params.to_unsafe_hash[:global_filter][:order_to_date].present?
            @orders = @orders.where('order_date <= ?', params.to_unsafe_hash[:global_filter][:order_to_date].to_date.end_of_day)
          end

          render layout: nil
        end

        def purchases_order_details
          @order = Erp::Orders::Order.find(params[:id])

          render layout: nil
        end

        def deliveries_purchases
          @order_detail = Erp::Orders::OrderDetail.find(params[:id])

          render layout: nil
        end

      end
    end
  end
end
