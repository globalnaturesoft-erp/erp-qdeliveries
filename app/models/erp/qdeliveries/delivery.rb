module Erp::Qdeliveries
  class Delivery < ApplicationRecord
    validates :code, :date, :customer_id, :supplier_id, :employee_id, :creator_id, :presence => true

    belongs_to :employee, class_name: "Erp::User"
    belongs_to :creator, class_name: "Erp::User"

    has_many :delivery_details, inverse_of: :delivery, dependent: :destroy
    accepts_nested_attributes_for :delivery_details, :reject_if => lambda { |a| a[:order_detail_id].blank? || a[:quantity].blank? || a[:quantity].to_i <= 0 }

    # class const
    TYPE_IMPORT = 'import'
    TYPE_EXPORT = 'export'
    STATUS_DELIVERED = 'delivered'
    STATUS_DELETED = 'deleted'
    TYPE_WAREHOUSE_IMPORT = 'warehouse_import'
    TYPE_WAREHOUSE_EXPORT = 'warehouse_export'
    TYPE_CUSTOMER_IMPORT = 'customer_import'
    TYPE_MANUFACTURER_EXPORT = 'manufacturer_export'

    def creator_name
      creator.present? ? creator.name : ''
    end

    def employee_name
      employee.present? ? employee.name : ''
    end

    if Erp::Core.available?("contacts")
      belongs_to :customer, class_name: "Erp::Contacts::Contact"
      belongs_to :supplier, class_name: "Erp::Contacts::Contact"

      def customer_name
        customer.present? ? customer.contact_name : ''
      end
      def supplier_name
        supplier.present? ? supplier.contact_name : ''
      end
    end

    # Filters
    def self.filter(query, params)
      params = params.to_unsafe_hash
      and_conds = []
      show_archived = false

      #filters
      if params["filters"].present?
        params["filters"].each do |ft|
          or_conds = []
          ft[1].each do |cond|
            # in case filter is show archived
            if cond[1]["name"] == 'show_archived'
              show_archived = true
            else
              or_conds << "#{cond[1]["name"]} = '#{cond[1]["value"]}'"
            end
          end
          and_conds << '('+or_conds.join(' OR ')+')' if !or_conds.empty?
        end
      end

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

      # join with users table for search creator
      query = query.joins(:creator)

      # showing archived items if show_archived is not true
      query = query.where(archived: false) if show_archived == false

      # add conditions to query
      query = query.where(and_conds.join(' AND ')) if !and_conds.empty?

      return query
    end

    def self.search(params)
      query = self.all
      query = self.filter(query, params)

      # order
      if params[:sort_by].present?
        order = params[:sort_by]
        order += " #{params[:sort_direction]}" if params[:sort_direction].present?

        query = query.order(order)
      end

      return query
    end

    # data for dataselect ajax
    def self.dataselect(keyword='')
      query = self.all

      if keyword.present?
        keyword = keyword.strip.downcase
        query = query.where('LOWER(name) LIKE ?', "%#{keyword}%")
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

    def fill_details(details)
      details.each do |row|
        data = row[1]
        if !data["id"].present?
          self.delivery_details.build(
            order_detail_id: data["order_detail_id"],
            quantity: data["quantity"],
            state_id: data["state_id"],
            warehouse_id: data["warehouse_id"],
            product_id: data["product_id"]
          )
        end
      end
    end

    def update_details(details)
      details.each do |row|
        data = row[1]
        if data["id"].present?
          self.delivery_details.find(data["id"]).update(
            order_detail_id: data["order_detail_id"],
            quantity: data["quantity"],
            state_id: data["state_id"],
            warehouse_id: data["warehouse_id"],
            product_id: data["product_id"]
          )
        end
      end
    end

    def destroy_details(details)
      ids = []
      details.each do |row|
        data = row[1]
        if data["id"].present? and data["_destroy"].present?
          self.delivery_details.find(data["id"]).destroy
        end
      end
    end
  end
end
