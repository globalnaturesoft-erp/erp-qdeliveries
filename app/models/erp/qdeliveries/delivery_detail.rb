module Erp::Qdeliveries
  class DeliveryDetail < ApplicationRecord
    validates :delivery, presence: true
    belongs_to :delivery, inverse_of: :delivery_details, class_name: "Erp::Qdeliveries::Delivery"
    belongs_to :product, class_name: "Erp::Products::Product", optional: true
    if Erp::Core.available?("taxes")
			belongs_to :tax, class_name: "Erp::Taxes::Tax", foreign_key: :tax_id, optional: true
      
			# tax name
			def tax_name
				if tax.present?
					tax.short_name.present? ? tax.short_name : tax.name
				end
			end
		end

    STATUS_DELIVERED = 'deliveried'
    STATUS_NOT_DELIVERY = 'not_delivery'
    STATUS_OVER_DELIVERED = 'over_deliveried'
    STATUS_NO_ORDER = 'no_order'

    after_save :update_product_cache_stock
    # after_save :update_delivery_cache_total

    # update product cache stock
    def update_product_cache_stock
			self.product.update_cache_stock if self.product.present?
		end

#    # update delivery cache total
#    def update_delivery_cache_total
#			if delivery.present?
#				delivery.update_cache_total
#			end
#		end

    def price=(new_price)
      self[:price] = new_price.to_s.gsub(/\,/, '')
    end

    def discount_amount=(new_price)
      self[:discount_amount] = new_price.to_s.gsub(/\,/, '')
    end

    def discount_percent=(new_price)
      self[:discount_percent] = new_price.to_s.gsub(/\,/, '')
    end

    def quantity=(number)
      self[:quantity] = number.to_s.gsub(/\,/, '')
    end

    def cache_total=(new_price)
      self[:cache_total] = new_price.to_s.gsub(/\,/, '')
    end

    def get_delivery_code
      delivery.present? ? delivery.code : ''
    end

    def get_max_quantity
      max = 10000

      prod = order_detail.present? ? order_detail.product : self.product
      #stock = prod.present? ? Erp::Products::CacheStock.get_stock(prod.id, {warehouse_id: self.warehouse_id, state_id: self.state_id}) : 0
      stock = prod.present? ? prod.get_stock(warehouse_ids: self.warehouse_id, state_ids: self.state_id) : 0

      if order_detail_id.present?
        if [Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT, Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT].include?(delivery.delivery_type)
          max = self.id.nil? ? order_detail.delivered_quantity : order_detail.delivered_quantity + DeliveryDetail.find(self.id).quantity
        elsif [Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT, Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT].include?(delivery.delivery_type)
          max = self.id.nil? ? order_detail.not_delivered_quantity : order_detail.not_delivered_quantity + DeliveryDetail.find(self.id).quantity
        end
      end

      # 
      if [Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT, Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT, Erp::Qdeliveries::Delivery::TYPE_CUSTOM_EXPORT].include?(delivery.delivery_type)
        stock = stock + DeliveryDetail.find(self.id).quantity if prod.present? and self.id.present?
        max = (stock < max) ? stock : max
      end

      max
    end

    if Erp::Core.available?("orders")
      #after_save :order_update_cache_delivery_status
      #after_save :update_order_detail_cache_delivery_status

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

      def get_eye_position
        if order_detail.present?
          order_detail.display_eye_position
        else
          return ''
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
    # ==========================================
    # @todo validates when quantity nil?
    def subtotal
			quantity.to_f*price.to_f
		end

    # get discount amount
    def discount_am
			discount_amount.nil? ? 0.0 : discount_amount
		end
    
    def discount_per
			discount_percent.nil? ? 0.0 : discount_percent
		end
    
    DISCOUNT_COMPUTATION_AMOUNT = 'amount'
    DISCOUNT_COMPUTATION_PERCENT = 'percent'
    
    def calculate_discount(options={})
      if options[:computation].present?
        if options[:computation] == Erp::Qdeliveries::DeliveryDetail::DISCOUNT_COMPUTATION_AMOUNT
          return (discount_am/subtotal)*100
        elsif options[:computation] == Erp::Qdeliveries::DeliveryDetail::DISCOUNT_COMPUTATION_PERCENT
          return subtotal*(discount_per/100)
        end
      else
        return nil
      end
    end
    
    #def tinh_giam_gia
    #  if discount_amount.present?
    #    discount_percent = 1000
    #  elsif discount_percent.present?
    #    discount_amount = 20000
    #  end
    #end

    # total before tax
    def total_without_tax
			subtotal - discount_am
		end

    # tax amount
    def tax_amount
			count = 0
			if tax.present?
        if tax.computation == Erp::Taxes::Tax::TAX_COMPUTATION_FIXED
          count = tax.amount
        elsif tax.computation == Erp::Taxes::Tax::TAX_COMPUTATION_PRICE
          count = (total_without_tax*(tax.amount))/100
        end
      end
			return count
		end

    # total after tax
    def total
			total_without_tax + tax_amount
		end
    
    # ==========================================

    # total amount (if product return)
    def total_amount
			quantity.to_f*price.to_f
		end

    # Cache total
    def self.cache_total
			self.sum("erp_qdeliveries_delivery_details.cache_total")
		end
    
    def ordered_price
      order_detail.present? ? order_detail.price : nil
    end
    
    def ordered_subtotal
      ordered_price.nil? ? nil : ordered_price.to_f*quantity.to_f
    end
    
    def discount
      if !ordered_subtotal.nil?
        ordered_subtotal - total_amount
      end
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
      return nil if self.order_detail.nil?

      # return order detail serials if existed
      return self.order_detail.serials if self.order_detail.serials.present?

      # find from schecks
      if !self.order_detail.order.nil? and !self.order_detail.order.schecks.empty?
        scheck = self.order_detail.order.schecks.last

        scheck.scheck_details.each do |scd|
          serials = scd.get_alternative_serials_by_product_id(self.order_detail.product_id)
          return serials if serials.present?
        end
      end

      return nil
    end
    
    
    # get_returned_confirmed_delivery_details
    def self.get_returned_confirmed_delivery_details(options={})
      query = Erp::Qdeliveries::DeliveryDetail.joins(:delivery)
        .where(erp_qdeliveries_deliveries: {
          status: Erp::Qdeliveries::Delivery::STATUS_DELIVERED,
          delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT
        })

      if options[:from_date].present?
				query = query.where('erp_qdeliveries_deliveries.date >= ?', options[:from_date].to_date.beginning_of_day)
			end

			if options[:to_date].present?
				query = query.where('erp_qdeliveries_deliveries.date <= ?', options[:to_date].to_date.end_of_day)
			end
			
			if Erp::Core.available?("ortho_k")
        if options[:patient_state_id].present?          
          if options[:patient_state_id] == -1
            query = query.where(order_detail_id: nil)
          else
            query = query.joins(:order_detail => :order)
            query = query.where('erp_orders_orders.patient_state_id = ?', options[:patient_state_id])
          end
        end
      end

			if Erp::Core.available?("periods")
				if options[:period].present?
					query = query.where('erp_qdeliveries_deliveries.date >= ? AND erp_qdeliveries_deliveries.date <= ?',
            Erp::Periods::Period.find(options[:period]).from_date.beginning_of_day,
            Erp::Periods::Period.find(options[:period]).to_date.end_of_day)
				end
			end
			
			query
    end
  end
end
