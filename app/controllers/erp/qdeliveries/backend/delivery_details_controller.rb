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
            @delivery_detail.tax = Erp::Taxes::Tax.new
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
          
          @delivery_detail.patient_id = @params[:patient_id] if @params[:patient_id].present?
          @delivery_detail.patient_state_id = @params[:patient_state_id] if @params[:patient_state_id].present?
          @delivery_detail.note = @params[:note] if @params[:note].present?
          @delivery_detail.quantity = @params[:quantity] if @params[:quantity].present?
          @delivery_detail.price = @params[:price] if @params[:price].present?
          @delivery_detail.discount_amount = @params[:discount_amount] if @params[:discount_amount].present?
          @delivery_detail.discount_percent = @params[:discount_percent] if @params[:discount_percent].present?
          @delivery_detail.warehouse = Erp::Warehouses::Warehouse.find(@params[:warehouse_id]) if @params[:warehouse_id].present?
          @delivery_detail.tax = Erp::Taxes::Tax.find(@params[:tax_id]) if @params[:tax_id].present?

          @delivery_detail.order_detail.product = Erp::Products::Product.find(@params[:product_id]) if @params[:product_id].present?
          @delivery_detail.state = Erp::Products::State.find(@params[:state_id]) if @params[:state_id].present?
          @delivery_detail.serials = @params[:serials] if @params[:serials].present?

          # select defferent order
          if @delivery_detail.order_detail.order_id.to_i > 0 and !@delivery_detail.order_detail.product.id.nil?
            odq = @delivery_detail.order_detail.order.order_details.where(product_id: @delivery_detail.order_detail.product_id)
            odq = odq.where(warehouse_id: @params[:warehouse_id]) if @params[:warehouse_id].present?
            @delivery_detail.order_detail = odq.first
            @delivery_detail.quantity = @delivery_detail.get_max_quantity if !@params[:quantity].present?
          end
          
          # fill discount
          @current_control = params.to_unsafe_hash[:current_control].to_s
          if @current_control.include?("discount_amount")
            @delivery_detail.discount_percent = @delivery_detail.calculate_discount(computation: Erp::Qdeliveries::DeliveryDetail::DISCOUNT_COMPUTATION_AMOUNT)
          elsif @current_control.include?("discount_percent")
            @delivery_detail.discount_amount = @delivery_detail.calculate_discount(computation: Erp::Qdeliveries::DeliveryDetail::DISCOUNT_COMPUTATION_PERCENT)
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
