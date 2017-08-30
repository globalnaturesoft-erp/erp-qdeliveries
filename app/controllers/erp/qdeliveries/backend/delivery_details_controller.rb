module Erp
  module Qdeliveries
    module Backend
      class DeliveryDetailsController < Erp::Backend::BackendController
        def form_detail
          @params = params.to_unsafe_hash[:details].present? ? params.to_unsafe_hash[:details] : {}

          if params[:id].present?
            @delivery_detail = Erp::Qdeliveries::DeliveryDetail.find(@params[:id])

            @diameter = @delivery_detail.order_detail.product.get_diameter
          else
            @delivery_detail = Erp::Qdeliveries::DeliveryDetail.new
            @delivery_detail.order_detail = Erp::Orders::OrderDetail.new
            @delivery_detail.order_detail.order = Erp::Orders::Order.new
            @delivery_detail.order_detail.product = Erp::Products::Product.new
            @delivery_detail.order_detail.product.category = Erp::Products::Category.new
            @delivery_detail.warehouse = Erp::Warehouses::Warehouse.new
            @delivery_detail.state = Erp::Products::State.first

            @delivery_detail.order_detail.order = Erp::Orders::Order.find(@params[:order_id]) if @params[:order_id].present? and @params[:order_id] != '-1'
            if @params[:order_id] == '-1'
              @delivery_detail.order_detail.order.id == -1
              @delivery_detail.order_detail.order.code = '-Không chứng từ-'
            end

            @delivery_detail.order_detail.product.code = @params[:product_code] if @params[:product_code].present?
            @delivery_detail.order_detail.product.category = Erp::Products::Category.find(@params[:category_id]) if @params[:category_id].present?

            @delivery_detail.quantity = (@params[:quantity].present? ? @params[:quantity].to_i : 1)
            @delivery_detail.warehouse = Erp::Warehouses::Warehouse.find(@params[:warehouse_id]) if @params[:warehouse_id].present?

            @delivery_detail.order_detail.product = Erp::Products::Product.find(@params[:product_id]) if @params[:product_id].present?
            @delivery_detail.state = Erp::Products::State.find(@params[:state_id]) if @params[:state_id].present?

            @diameter = (@params[:diameter].present? ? Erp::Products::PropertiesValue.find(@params[:diameter]) : Erp::Products::PropertiesValue.new)

          end

          render partial: 'erp/qdeliveries/backend/delivery_details/form_detail'
        end
      end
    end
  end
end
