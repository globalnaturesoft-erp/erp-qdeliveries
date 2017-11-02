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

    def get_delivery_code
      delivery.present? ? delivery.code : ''
    end

    def get_max_quantity
      self.id.nil? ? order_detail.not_delivered_quantity : order_detail.not_delivered_quantity + DeliveryDetail.find(self.id).quantity
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
  end
end
