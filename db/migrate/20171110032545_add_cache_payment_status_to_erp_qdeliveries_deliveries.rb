class AddCachePaymentStatusToErpQdeliveriesDeliveries < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_qdeliveries_deliveries, :cache_payment_status, :string
  end
end
