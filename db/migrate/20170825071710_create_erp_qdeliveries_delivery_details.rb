class CreateErpQdeliveriesDeliveryDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :erp_qdeliveries_delivery_details do |t|
      t.integer :quantity
      t.references :order_detail, index: true, references: :erp_orders_order_details
      t.references :state, index: true, references: :erp_products_states      
      t.references :warehouse, index: true, references: :erp_warehouses_warehouses
      t.references :delivery, index: true, references: :erp_deliveries_deliveries
      t.text :note

      t.timestamps
    end
  end
end
