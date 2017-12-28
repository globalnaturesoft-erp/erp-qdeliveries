class AddCacheTotalToErpQdeliveriesDeliveries < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_qdeliveries_deliveries, :cache_total, :decimal
  end
end
