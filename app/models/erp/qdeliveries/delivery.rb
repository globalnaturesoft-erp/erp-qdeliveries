module Erp::Qdeliveries
  class Delivery < ApplicationRecord

		#validates :code, uniqueness: true
    validates :date, :employee_id, :creator_id, :presence => true

    belongs_to :employee, class_name: "Erp::User"
    belongs_to :creator, class_name: "Erp::User"

    has_many :delivery_details, inverse_of: :delivery, dependent: :destroy
    accepts_nested_attributes_for :delivery_details, :reject_if => lambda { |a| a[:order_detail_id].blank? || a[:quantity].blank? || a[:quantity].to_i <= 0 }

    # class const
    TYPE_IMPORT = 'import'
    TYPE_EXPORT = 'export'
    STATUS_DELIVERED = 'delivered'
    STATUS_DELETED = 'deleted'

    TYPE_SALES_EXPORT = 'sales_export'
    TYPE_SALES_IMPORT = 'sales_import'
    TYPE_PURCHASE_IMPORT = 'purchase_import'
    TYPE_PURCHASE_EXPORT = 'purchase_export'
    TYPE_CUSTOM_IMPORT = 'custom_import'
    TYPE_CUSTOM_EXPORT = 'custom_export'

    PAYMENT_FOR_ORDER = 'for_order'
    PAYMENT_FOR_CONTACT = 'for_contact'

    after_save :update_product_cache_stock
    after_save :order_update_cache_delivery_status
    after_save :update_cache_total
    after_save :update_delivery_detail_cache_total

    def order_update_cache_delivery_status
      Erp::Orders::Order.where(id: delivery_details.joins(:order_detail => :order).select('erp_orders_orders.id')).each do |o|
        o.update_cache_delivery_status
      end
    end

    # update product cache stock
    def update_product_cache_stock
			self.delivery_details.each do |dd|
        dd.update_product_cache_stock
      end
		end

    # Update delivery cache total
    def update_cache_total
			self.update_column(:cache_total, self.total_amount)
		end

    # update cache total for delivery_detail
    def update_delivery_detail_cache_total
			self.delivery_details.each do |dd|
        dd.update_cache_total
      end
		end

    def creator_name
      creator.present? ? creator.name : ''
    end

    def employee_name
      employee.present? ? employee.name : ''
    end

    # get payment type
    def self.get_payment_type_options()
      [
        {text: I18n.t('qdeliveries.payment_for_order'), value: Erp::Qdeliveries::Delivery::PAYMENT_FOR_ORDER},
        {text: I18n.t('qdeliveries.payment_for_contact'), value: Erp::Qdeliveries::Delivery::PAYMENT_FOR_CONTACT}
      ]
    end

    if Erp::Core.available?("contacts")
      belongs_to :customer, class_name: "Erp::Contacts::Contact", optional: true
      belongs_to :supplier, class_name: "Erp::Contacts::Contact", optional: true

      def customer_code
        customer.present? ? customer.code : ''
      end

      def supplier_code
        supplier.present? ? supplier.code : ''
      end

      def customer_name
        customer.present? ? customer.contact_name : ''
      end

      def supplier_name
        supplier.present? ? supplier.contact_name : ''
      end

      # Get contact
      def get_contact
        if [Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT,
            Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT].include?(delivery_type)
          if customer.present?
            query = customer
          else
            query = supplier
          end
        end
        if [Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT,
            Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT].include?(delivery_type)
          if supplier.present?
            query = supplier
          else
            query = customer
          end
        end

        return query#{name: query.contact_name, address: query.address}
      end
    end

    def total_delivery_quantity
      delivery_details.sum(:quantity)
    end

    def self.total_delivery_quantity
      self.sum(&:total_delivery_quantity)
    end

    # Filters
    def self.filter(query, params)
      params = params.to_unsafe_hash
      and_conds = []

      # show archived items condition - default: false
      show_archived = false

      #filters
      if params["filters"].present?
        params["filters"].each do |ft|
          or_conds = []
          ft[1].each do |cond|
            # in case filter is show archived
            if cond[1]["name"] == 'show_archived'
              # show archived items
              show_archived = true
            else
              or_conds << "#{cond[1]["name"]} = '#{cond[1]["value"]}'"
            end
          end
          and_conds << '('+or_conds.join(' OR ')+')' if !or_conds.empty?
        end
      end

      #keywords
      if params["keywords"].present?
        params["keywords"].each do |kw|
          or_conds = []
          kw[1].each do |cond|
            or_conds << "LOWER(#{cond[1]["name"]}) LIKE '%#{cond[1]["value"].downcase.strip}%'"
          end
          and_conds << '('+or_conds.join(' OR ')+')'
        end
      end

      # global filter
      global_filter = params[:global_filter]

      if global_filter.present?

				# filter by customer
				if global_filter[:customer_id].present?
					query = query.where(customer_id: global_filter[:customer_id])
				end

				# filter by supplier
				if global_filter[:supplier_id].present?
					query = query.where(supplier_id: global_filter[:supplier_id])
				end

				# if has period
        if global_filter[:period].present?
          period = Erp::Periods::Period.find(global_filter[:period])
          global_filter[:from_date] = period.from_date
          global_filter[:to_date] = period.to_date
        end

				# filter by order from date
				if global_filter[:from_date].present?
					query = query.where('date >= ?', global_filter[:from_date].to_date.beginning_of_day)
				end

				# filter by order to date
				if global_filter[:to_date].present?
					query = query.where('date <= ?', global_filter[:to_date].to_date.end_of_day)
				end
        
        # @todo // chuyển về chung 1 kiểu (customer_id ~ customer, supplier_id >< supplier)
				# filter by customer_id
				if global_filter[:customer].present?
					query = query.where(customer_id: global_filter[:customer])
				end

				# filter by customer_id
				if global_filter[:supplier].present?
					query = query.where(supplier_id: global_filter[:supplier])
				end

				# filter by employee_id
				if global_filter[:employee].present?
					query = query.where(employee_id: global_filter[:employee])
				end

			end
      # end// global filter

      # join with users table for search creator
      query = query.joins(:creator)

      # showing archived items if show_archived is not true
      query = query.where(archived: false) if show_archived == false

      # add conditions to query
      query = query.where(and_conds.join(' AND ')) if !and_conds.empty?
      
      # single keyword
      if params[:keyword].present?
				keyword = params[:keyword].strip.downcase
				keyword.split(' ').each do |q|
					q = q.strip
					query = query.where('LOWER(erp_qdeliveries_deliveries.cache_search) LIKE ?', '%'+q+'%')
				end
			end

      return query
    end

    def self.search(params)
      query = self.all
      query = self.filter(query, params)

      # order
      if params[:sort_by].present?
        order = params[:sort_by]
        order += " #{params[:sort_direction]}" if params[:sort_direction].present?

        query = query.order(order + ", erp_qdeliveries_deliveries.created_at #{params[:sort_direction].to_s}")
      end

      return query
    end
    
    after_save :update_cache_search
		def update_cache_search
			str = []
			str << code.to_s.downcase.strip
			if self.get_contact.present?
        str << get_contact.contact_name.to_s.downcase.strip
      end
			str << employee_name.to_s.downcase.strip
			if !self.get_related_order.nil?
        str << get_related_order.code.to_s.downcase.strip
      end

			self.update_column(:cache_search, str.join(" ") + " " + str.join(" ").to_ascii)
		end

    # data for dataselect ajax
    def self.dataselect(keyword='', params={})
      query = self.all

      if keyword.present?
        keyword = keyword.strip.downcase
        query = query.where('LOWER(code) LIKE ?', "%#{keyword}%")
      end

      # filter by status
      if params[:status].present?
				query = query.where(status: params[:status])
			end

      # filter by delivery_type
      if params[:delivery_type].present?
				query = query.where(delivery_type: params[:delivery_type])
			end

      query = query.limit(8).map{|delivery| {value: delivery.id, text: delivery.code} }
    end

    def archive
			update_attributes(archived: true)
		end

    def unarchive
			update_attributes(archived: false)
		end

    def status_delivered
			update_attributes(status: Erp::Qdeliveries::Delivery::STATUS_DELIVERED)
		end

    def status_deleted
			update_attributes(status: Erp::Qdeliveries::Delivery::STATUS_DELETED)
		end

    def self.archive_all
			update_all(archived: true)
		end

    def self.unarchive_all
			update_all(archived: false)
		end

    def self.status_delivered_all
			update_all(status: Erp::Qdeliveries::Delivery::STATUS_DELIVERED)
		end

    def self.status_deleted_all
			update_all(status: Erp::Qdeliveries::Delivery::STATUS_DELETED)
		end
    
    # check if status if delivered
    def is_delivered?
      return self.status == Erp::Qdeliveries::Delivery::STATUS_DELIVERED
    end

		# check if status if deleted
		def is_deleted?
			return self.status == Erp::Qdeliveries::Delivery::STATUS_DELETED
		end

    # Get all active deliveries
    def self.all_delivered
      self.where(status: Erp::Qdeliveries::Delivery::STATUS_DELIVERED)
    end

    def fill_details(details, force=false)
      return if !details.present?

      details.each_with_index do |row, index|
        data = row[1]
        if data['_ignore'] != 'true'
          if (!data["id"].present? or force) and data["_destroy"] != 'true'
            self.delivery_details.build(
              id: data["id"],
              order_detail_id: data["order_detail_id"],
              quantity: data["quantity"],
              state_id: data["state_id"],
              warehouse_id: data["warehouse_id"],
              product_id: data["product_id"],
              price: data["price"],
              discount_amount: data["discount_amount"],
              discount_percent: data["discount_percent"],
              tax_id: data["tax_id"],
              serials: data["serials"],
              note: data["note"],
              patient_id: data["patient_id"],
              patient_state_id: data["patient_state_id"],
            )
          end
        end
      end
    end

    def update_details(details)
      return false if !details.present?

      details.each do |row|
        data = row[1]
        if data['_ignore'] != 'true'
          if data["id"].present? and data["_destroy"].present?
            self.delivery_details.find(data["id"]).destroy
          elsif data["id"].present?
            self.delivery_details.find(data["id"]).update(
              order_detail_id: data["order_detail_id"],
              quantity: data["quantity"],
              state_id: data["state_id"],
              warehouse_id: data["warehouse_id"],
              product_id: data["product_id"],
              price: data["price"],
              discount_amount: data["discount_amount"],
              discount_percent: data["discount_percent"],
              tax_id: data["tax_id"],
              serials: data["serials"],
              note: data["note"],
              patient_id: data["patient_id"],
              patient_state_id: data["patient_state_id"],
            )
          elsif !data["id"].present? and data["_destroy"] != 'true'
            self.delivery_details.create(
              order_detail_id: data["order_detail_id"],
              quantity: data["quantity"],
              state_id: data["state_id"],
              warehouse_id: data["warehouse_id"],
              product_id: data["product_id"],
              price: data["price"],
              discount_amount: data["discount_amount"],
              discount_percent: data["discount_percent"],
              tax_id: data["tax_id"],
              serials: data["serials"],
              note: data["note"],
              patient_id: data["patient_id"],
              patient_state_id: data["patient_state_id"],
            )
          end
        end
      end
    end

    def destroy_details(details)
      return if !details.present?

      ids = []
      details.each do |row|
        data = row[1]
        if data["id"].present? and data["_destroy"].present?
          self.delivery_details.find(data["id"]).destroy
        end
      end
    end

    if Erp::Core.available?("payments")
			has_many :payment_records, class_name: "Erp::Payments::PaymentRecord"
		end

		# get pay payment records for order
		def done_paid_payment_records
			self.payment_records.all_done.all_paid
		end

		# get receice payment records for order
		def done_receiced_payment_records
			self.payment_records.all_done.all_received
		end

		# get total amount
		def subtotal
			return delivery_details.sum(&:subtotal)
		end

		def self.subtotal
			self.sum(&:subtotal)
		end
		
		def total_without_tax
			return delivery_details.sum(&:total_without_tax)
		end

		def self.total_without_tax
			self.sum(&:total_without_tax)
		end
		
		def tax_amount
			return delivery_details.sum(&:tax_amount)
		end

		def self.tax_amount
			self.sum(&:tax_amount)
		end
		
		def total
			return delivery_details.sum(&:total)
		end

		def self.total
			self.sum(&:total)
		end
		
		# will remove
		def total_amount
			return delivery_details.sum(&:total_amount)
		end

		def self.total_amount
			self.sum(&:total_amount)
		end
		# ###########

		def self.cache_total_amount
      self.sum("erp_qdeliveries_deliveries.cache_total")
    end
		
		# if orders engine available // Start
		def ordered_subtotal
      return delivery_details.map(&:ordered_subtotal).sum(&:to_f)
    end
		
		def self.ordered_subtotal
      self.sum(&:ordered_subtotal)
    end
		
		def discount
      return delivery_details.map(&:discount).sum(&:to_f)
    end
		
		def self.discount
      self.sum(&:discount)
    end
		# if orders engine available // End

		# get paid amount
		def paid_amount
			self.done_paid_payment_records.sum(:amount) - self.done_receiced_payment_records.sum(:amount)
		end

		# get remain amount
		def remain_amount
			return total_amount - paid_amount
		end
		
		# check if delivery is sales import
		def sales_import?
      return self.delivery_type == Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT
    end
		
		# check if delivery is purchase export
		def purchase_export?
      return self.delivery_type == Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT
    end

		#
		def import(file)
      spreadsheet = Roo::Spreadsheet.open(file.path)
      header = spreadsheet.row(1)

      (2..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]

        # Find product
        # p_name = "#{row["code"].to_s.strip}-#{row["diameter"].to_s.strip}-#{row["category"].to_s.strip}"
        p_name = "#{row["name"].to_s.strip}"
        product = Erp::Products::Product.where('LOWER(name) = ?', p_name.strip.downcase).first
        product_id = product.present? ? product.id : nil

        # Find state
        state = Erp::Products::State.where('LOWER(name) = ?', row["state"].strip.downcase).first
        state_id = state.present? ? state.id : nil

        # Find warehouse
        warehouse = Erp::Warehouses::Warehouse.where('LOWER(name) = ?', row["warehouse"].strip.downcase).first
        warehouse_id = warehouse.present? ? warehouse.id : nil

        if product.present?
          self.delivery_details.build(
            order_detail_id: nil,
            state_id: state_id,
            product_id: product_id,
            warehouse_id: warehouse_id,
            quantity: row["quantity"],
            serials: row["serials"],
          )
        end
      end
    end

#		# Generate code
#    before_validation :generate_code
#    def generate_code
#			if !code.present?
#				# Bổ sung trường hợp lọc để set mã
#				if delivery_type == Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT or delivery_type == Erp::Qdeliveries::Delivery::TYPE_CUSTOM_IMPORT  # Nhập kho (mua hàng từ NCC)
#					query = Erp::Qdeliveries::Delivery.where(delivery_type: [Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT,
#																																	 Erp::Qdeliveries::Delivery::TYPE_CUSTOM_IMPORT])
#					str = 'NK'
#				elsif delivery_type == Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT or delivery_type == Erp::Qdeliveries::Delivery::TYPE_CUSTOM_EXPORT # Xuất kho trả hàng cho NCC
#					query = Erp::Qdeliveries::Delivery.where(delivery_type: [Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT,
#																																	 Erp::Qdeliveries::Delivery::TYPE_CUSTOM_EXPORT])
#					str = 'XK'
#				elsif delivery_type == Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT # Hoàn kho (hàng bị trả lại)
#					query = Erp::Qdeliveries::Delivery.where(delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT)
#					str = 'HK'
#				elsif delivery_type == Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT # Xuất bán
#					query = Erp::Qdeliveries::Delivery.where(delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT)
#					str = 'XB'
#				end
#
#				# NK : nhập kho, mua hàng từ nhà cung cấp
#				# XK : xuất kho trả hàng NCC
#				# HK : hoàn kho, hàng bị trả lại
#				# XB : xuất hàng bán
#				num = query.where('date >= ? AND date <= ?', self.date.beginning_of_month, self.date.end_of_month).count + 1
#
#				self.code = str + date.strftime("%m") + date.strftime("%Y").last(2) + "-" + num.to_s.rjust(3, '0') + " / " + Time.now.to_i.to_s
#			end
#		end

    # force generate code
    after_create :force_generate_code
    def force_generate_code
      #if !code.present?
        # Bổ sung trường hợp lọc để set mã
        if delivery_type == Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT or delivery_type == Erp::Qdeliveries::Delivery::TYPE_CUSTOM_IMPORT  # Nhập kho (mua hàng từ NCC)
          query = Erp::Qdeliveries::Delivery.where(delivery_type: [Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT,
                                                                   Erp::Qdeliveries::Delivery::TYPE_CUSTOM_IMPORT])
          str = 'NK'
        elsif delivery_type == Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT or delivery_type == Erp::Qdeliveries::Delivery::TYPE_CUSTOM_EXPORT # Xuất kho trả hàng cho NCC
          query = Erp::Qdeliveries::Delivery.where(delivery_type: [Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT,
                                                                   Erp::Qdeliveries::Delivery::TYPE_CUSTOM_EXPORT])
          str = 'XK'
        elsif delivery_type == Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT # Hoàn kho (hàng bị trả lại)
          query = Erp::Qdeliveries::Delivery.where(delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT)
          str = 'HK'
        elsif delivery_type == Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT # Xuất bán
          query = Erp::Qdeliveries::Delivery.where(delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT)
          str = 'XB'
        end

        # NK : nhập kho, mua hàng từ nhà cung cấp
        # XK : xuất kho trả hàng NCC
        # HK : hoàn kho, hàng bị trả lại
        # XB : xuất hàng bán
        num = query.where('date >= ? AND date <= ?', self.date.beginning_of_month, self.date.end_of_month)
        num = num.where('created_at <= ?', self.created_at).count

        self.update_column(:code, str + date.strftime("%m") + date.strftime("%Y").last(2) + "-" + num.to_s.rjust(3, '0'))
      #end
		end

    # Get deliveries with payment for order
    def self.get_deliveries_with_payment_for_order(params={})
      query = self.where(payment_for: Erp::Qdeliveries::Delivery::PAYMENT_FOR_ORDER)

      if params[:from_date].present?
				query = query.where('date >= ?', params[:from_date].to_date.beginning_of_day)
			end

			if params[:to_date].present?
				query = query.where('date <= ?', params[:to_date].to_date.end_of_day)
			end

			if Erp::Core.available?("periods")
				if params[:period].present?
					query = query.where('date >= ? AND date <= ?',
            Erp::Periods::Period.find(params[:period]).from_date.beginning_of_day,
            Erp::Periods::Period.find(params[:period]).to_date.end_of_day)
				end
			end

			return query
    end

    # Get deliveries with payment for contact
    def self.get_deliveries_with_payment_for_contact(params={})
      query = self.where(payment_for: Erp::Qdeliveries::Delivery::PAYMENT_FOR_CONTACT)

      if params[:from_date].present?
				query = query.where('date >= ?', params[:from_date].to_date.beginning_of_day)
			end

			if params[:to_date].present?
				query = query.where('date <= ?', params[:to_date].to_date.end_of_day)
			end

			if Erp::Core.available?("periods")
				if params[:period].present?
					query = query.where('date >= ? AND date <= ?',
            Erp::Periods::Period.find(params[:period]).from_date.beginning_of_day,
            Erp::Periods::Period.find(params[:period]).to_date.end_of_day)
				end
			end

			return query
    end

    # Get deliveries is sales import
    def self.sales_import_deliveries(params={})
      query = self.where(delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_IMPORT)
      
      if params[:from_date].present?
				query = query.where('date >= ?', params[:from_date].to_date.beginning_of_day)
			end

			if params[:to_date].present?
				query = query.where('date <= ?', params[:to_date].to_date.end_of_day)
			end

			if Erp::Core.available?("periods")
				if params[:period].present?
					query = query.where('date >= ? AND date <= ?',
            Erp::Periods::Period.find(params[:period]).from_date.beginning_of_day,
            Erp::Periods::Period.find(params[:period]).to_date.end_of_day)
				end
			end
			
			query
    end

    # Get deliveries is sales export

    # Get deliveries is purchase import

    # Get deliveries is purchase export
    def self.purchase_export_deliveries(params={})
      query = self.where(delivery_type: Erp::Qdeliveries::Delivery::TYPE_PURCHASE_EXPORT)
     
      if params[:from_date].present?
				query = query.where('date >= ?', params[:from_date].to_date.beginning_of_day)
			end

			if params[:to_date].present?
				query = query.where('date <= ?', params[:to_date].to_date.end_of_day)
			end

			if Erp::Core.available?("periods")
				if params[:period].present?
					query = query.where('date >= ? AND date <= ?',
            Erp::Periods::Period.find(params[:period]).from_date.beginning_of_day,
            Erp::Periods::Period.find(params[:period]).to_date.end_of_day)
				end
			end
			
			query
    end

    # Get deliveries is custom import

    # Get deliveries is custom export

    # Get related order
    def get_related_order
      order_id = nil
      delivery_details.each_with_index do |dd,index|
        if dd.order_detail.present?
          order_id = dd.order_detail.order_id if order_id == nil
          if order_id != dd.order_detail.order_id
            order_id = nil
            break
          end
        else
          order_id = nil
          break
        end
      end
      return order_id.nil? ? nil : Erp::Orders::Order.find(order_id)
    end
  end
end
