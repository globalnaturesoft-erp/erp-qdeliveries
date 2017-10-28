class AddPriceToErpQdeliveriesDeliveryDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_qdeliveries_delivery_details, :price, :decimal
  end
end
