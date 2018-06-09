class AddDiscountAmountToErpQdeliveriesDeliveryDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_qdeliveries_delivery_details, :discount_amount, :decimal
  end
end
