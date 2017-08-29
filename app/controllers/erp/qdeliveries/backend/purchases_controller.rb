module Erp
  module Qdeliveries
    module Backend
      class PurchasesController < Erp::Backend::BackendController
    
        def purchases_orders
        end
        
        # POST /orders/list
        def purchases_orders_listing
          @orders = Erp::Orders::Order.purchase_orders.search(params).paginate(:page => params[:page], :per_page => 10)
          
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
        
      end
    end
  end
end