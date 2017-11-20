module Erp::Qdeliveries
  class DeliveryDetail < ApplicationRecord
    validates :delivery, presence: true
    belongs_to :delivery, inverse_of: :delivery_details, class_name: "Erp::Qdeliveries::Delivery"
    belongs_to :product, class_name: "Erp::Products::Product", optional: true

    STATUS_DELIVERED = 'deliveried'
    STATUS_NOT_DELIVERY = 'not_delivery'
    STATUS_OVER_DELIVERED = 'over_deliveried'
    STATUS_NO_ORDER = 'no_order'

    after_save :update_product_cache_stock

    # update product cache stock
    def update_product_cache_stock
			self.product.update_cache_stock
		end

    def price=(new_price)
      self[:price] = new_price.to_s.gsub(/\,/, '')
    end

    def cache_total=(new_price)
      self[:cache_total] = new_price.to_s.gsub(/\,/, '')
    end

    def get_delivery_code
      delivery.present? ? delivery.code : ''
    end

    def get_max_quantity
      if [Erp::Qdeliveries::Delivery::TYPE_CUSTOMER_IMPORT, Erp::Qdeliveries::Delivery::TYPE_MANUFACTURER_EXPORT].include?(delivery.delivery_type)
				self.id.nil? ? order_detail.delivered_quantity : order_detail.delivered_quantity + DeliveryDetail.find(self.id).quantity
			elsif [Erp::Qdeliveries::Delivery::TYPE_WAREHOUSE_IMPORT, Erp::Qdeliveries::Delivery::TYPE_WAREHOUSE_EXPORT].include?(delivery.delivery_type)
				self.id.nil? ? order_detail.not_delivered_quantity : order_detail.not_delivered_quantity + DeliveryDetail.find(self.id).quantity
			end
    end

    if Erp::Core.available?("orders")
      after_save :order_update_cache_delivery_status
      after_save :update_order_detail_cache_delivery_status

      belongs_to :order_detail, class_name: "Erp::Orders::OrderDetail", optional: true

      def get_order_code
        order_detail.present? ? order_detail.order.code : ''
      end

      def get_product
        order_detail.present? ? order_detail.product : self.product
      end

      def get_order
        order_detail.present? ? order_detail.order : ''
      end

      def product_code
        if order_detail.present?
          order_detail.product_code
        else product.present?
          product.code
        end
      end

      def product_name
        if order_detail.present?
          order_detail.product_name
        else product.present?
          product.name
        end
      end

      def product_unit
        if order_detail.present?
          order_detail.product_unit_name
        else product.present?
          product.unit_name
        end
      end

      def ordered_quantity
        order_detail.present? ? order_detail.quantity : 0
      end

      # order update cache payment status
			def order_update_cache_delivery_status
				if order_detail.present?
					order_detail.order.update_cache_delivery_status
				end
			end

			def update_order_detail_cache_delivery_status
				if order_detail.present?
					order_detail.update_cache_delivery_status
				end
			end

    end

    if Erp::Core.available?("products")
      belongs_to :state, class_name: "Erp::Products::State", optional: true
      belongs_to :product, class_name: "Erp::Products::Product", optional: true

      def state_name
        state.present? ? state.name : ''
      end
    end

    if Erp::Core.available?("warehouses")
      belongs_to :warehouse, class_name: "Erp::Warehouses::Warehouse"

      def warehouse_name
        warehouse.present? ? warehouse.name : ''
      end
    end
    
    # total amount (if product return)
    def total_amount
			quantity*price
		end
    
    # Update cache total
    after_save :update_cache_total
    def update_cache_total
			if [Erp::Qdeliveries::Delivery::TYPE_CUSTOMER_IMPORT, Erp::Qdeliveries::Delivery::TYPE_MANUFACTURER_EXPORT].include?(delivery.delivery_type)
				self.update_column(:cache_total, self.total_amount)
			end
		end
    
    def self.total_amount_by_delivery_type(params={})
			query = self.joins(:delivery).where(erp_qdeliveries_deliveries: {status: Erp::Qdeliveries::Delivery::STATUS_DELIVERED})
			
			if params[:delivery_type].present?
				query = query.where(erp_qdeliveries_deliveries: {delivery_type: params[:delivery_type]})
			end
				
			if params[:from_date].present?
				query = query.where('erp_qdeliveries_deliveries.date >= ?', params[:from_date].to_date.beginning_of_day)
			end
	
			if params[:to_date].present?
				query = query.where('erp_qdeliveries_deliveries.date <= ?', params[:to_date].to_date.end_of_day)
			end
			
			if Erp::Core.available?("periods")
				if params[:period].present?
					query = query.where('erp_qdeliveries_deliveries.date >= ? AND erp_qdeliveries_deliveries.date <= ?',
															Erp::Periods::Period.find(params[:period]).from_date.beginning_of_day,
															Erp::Periods::Period.find(params[:period]).to_date.end_of_day)
				end
			end
			
			return query.sum(:cache_total)
		end
  end
end
