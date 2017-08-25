module Erp::Qdeliveries
  class DeliveryDetail < ApplicationRecord
    validates :delivery, presence: true
    belongs_to :delivery, inverse_of: :delivery_details, class_name: "Erp::Qdeliveries::Delivery"
    
    if Erp::Core.available?("orders")
      validates :order_detail, presence: true
      
      belongs_to :order_detail, class_name: "Erp::Orders::OrderDetail"
    end
    
    if Erp::Core.available?("products")
      belongs_to :state, class_name: "Erp::Products::State", optional: true
    end
    
    if Erp::Core.available?("warehouses")
      belongs_to :warehouse, class_name: "Erp::Warehouses::Warehouse"
    end
  end
end
