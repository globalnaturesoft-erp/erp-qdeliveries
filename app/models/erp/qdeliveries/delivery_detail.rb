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
    after_save :update_delivery_cache_total

    # update product cache stock
    def update_product_cache_stock
			self.product.update_cache_stock if self.product.present?
		end

    # update delivery cache total
    def update_delivery_cache_total
			if delivery.present?
				delivery.update_cache_total
			end
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
      max = 10000

      if order_detail_id.present?
        if [Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT, Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT].include?(delivery.delivery_type)
          max = self.id.nil? ? order_detail.delivered_quantity : order_detail.delivered_quantity + DeliveryDetail.find(self.id).quantity
        elsif [Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT, Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT].include?(delivery.delivery_type)
          max = self.id.nil? ? order_detail.not_delivered_quantity : order_detail.not_delivered_quantity + DeliveryDetail.find(self.id).quantity
        end
      end

      prod = order_detail.present? ? order_detail.product : self.product
      stock = prod.present? ? Erp::Products::CacheStock.get_stock(prod.id, {warehouse_id: self.warehouse_id, state_id: self.state_id}) : 0
      
      # check if editing case
      stock = stock + DeliveryDetail.find(self.id).quantity if prod.present? and self.id.present?

      (stock < max) ? stock : max
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
			quantity.to_f*price.to_f
		end

    # Cache total
    def self.cache_total
			self.sum("erp_qdeliveries_delivery_details.cache_total")
		end

    # Update cache total
    after_save :update_cache_total
    def update_cache_total
			if [Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT, Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT].include?(delivery.delivery_type)
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

    # Find serials
    def find_serials
      return self.serials if !self.id.nil? or self.serials.present?
      return nil if self.order_detail.nil? or self.order_detail.order.nil? or self.order_detail.order.schecks.empty?

      scheck = self.order_detail.order.schecks.last

      scheck.scheck_details.each do |scd|
        serials = scd.get_alternative_serials_by_product_id(self.order_detail.product_id)
        return serials if serials.present?
      end

      return nil
    end
  end
end
