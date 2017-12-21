class AddPaymentForToErpQdeliveriesDeliveries < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_qdeliveries_deliveries, :payment_for, :string
  end
end
