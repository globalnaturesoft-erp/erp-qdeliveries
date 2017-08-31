class AddProductToErpQdeliveriesDeliveryDetails < ActiveRecord::Migration[5.1]
  def change
    add_reference :erp_qdeliveries_delivery_details, :product, index: true, references: :erp_products_products
  end
end
