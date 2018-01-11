module Erp
  module Qdeliveries
    module Backend
      class DeliveryDetailsController < Erp::Backend::BackendController
        def form_detail
          @delivery_type = params.to_unsafe_hash[:delivery_type]
          @params = params.to_unsafe_hash[:details].present? ? params.to_unsafe_hash[:details][params.to_unsafe_hash[:index]] : {}

          if @params[:id].present? and !@params[:order_id].present?
            @delivery_detail = Erp::Qdeliveries::DeliveryDetail.find(@params[:id])
          else
            @delivery_detail = Erp::Qdeliveries::DeliveryDetail.new
            @delivery_detail.order_detail = Erp::Orders::OrderDetail.new
            @delivery_detail.order_detail.order = Erp::Orders::Order.new
            @delivery_detail.order_detail.product = Erp::Products::Product.new
            @delivery_detail.order_detail.product.category = Erp::Products::Category.new
            @delivery_detail.warehouse = Erp::Warehouses::Warehouse.new
            @delivery_detail.state = Erp::Products::State.first
            @delivery_detail.quantity = 1
            @delivery_detail.id = @params[:id]

            # Tmp Delivery
            @delivery_detail.delivery = Erp::Qdeliveries::Delivery.new(delivery_type: @delivery_type)
          end

          @delivery_detail.order_detail.order_id = @params[:order_id] if @params[:order_id].present?

          ## if has order, get warehouse info
          #if @params[:order_id] and @params[:order_id] != -1
          #  @delivery_detail.warehouse_id = Erp::Orders::Order.find(@params[:order_id]).warehouse_id
          #end

          @delivery_detail.quantity = @params[:quantity].to_i if @params[:quantity].present?
          @delivery_detail.price = @params[:price] if @params[:price].present?
          @delivery_detail.warehouse = Erp::Warehouses::Warehouse.find(@params[:warehouse_id]) if @params[:warehouse_id].present?

          @delivery_detail.order_detail.product = Erp::Products::Product.find(@params[:product_id]) if @params[:product_id].present?
          @delivery_detail.state = Erp::Products::State.find(@params[:state_id]) if @params[:state_id].present?

          # select defferent order
          if @delivery_detail.order_detail.order_id.to_i > 0 and !@delivery_detail.order_detail.product.id.nil?
            @delivery_detail.order_detail = @delivery_detail.order_detail.order.order_details.where(product_id: @delivery_detail.order_detail.product.id).first
            @delivery_detail.quantity = @delivery_detail.get_max_quantity if !@params[:quantity].present?
          end

          render partial: 'erp/qdeliveries/backend/delivery_details/form_detail', locals: {
            delivery_detail: @delivery_detail,
            delivery_type: @delivery_type
          }
        end
      end
    end
  end
end
