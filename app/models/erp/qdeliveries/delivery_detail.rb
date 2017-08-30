module Erp::Qdeliveries
  class DeliveryDetail < ApplicationRecord
    validates :delivery, presence: true
    belongs_to :delivery, inverse_of: :delivery_details, class_name: "Erp::Qdeliveries::Delivery"
    
    STATUS_DELIVERED = 'deliveried'
    STATUS_NOT_DELIVERY = 'not_delivery'
    STATUS_OVER_DELIVERIED = 'over_deliveried'
    
    if Erp::Core.available?("orders")
      validates :order_detail, presence: true      
      belongs_to :order_detail, class_name: "Erp::Orders::OrderDetail"
      
      def get_order_code
        order_detail.present? ? order_detail.order.code : ''
      end
      
      def get_product
        order_detail.present? ? order_detail.product : ''
      end
      
      def get_order
        order_detail.present? ? order_detail.order : ''
      end
      
      def product_code
        order_detail.present? ? order_detail.product_code : ''
      end
      
      def product_name
        order_detail.present? ? order_detail.product_name : ''
      end
      
      def ordered_quantity
        order_detail.present? ? order_detail.quantity : ''
      end
      
    end
    
    if Erp::Core.available?("products")
      belongs_to :state, class_name: "Erp::Products::State", optional: true
      
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
