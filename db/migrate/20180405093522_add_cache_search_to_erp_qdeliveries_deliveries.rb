class AddCacheSearchToErpQdeliveriesDeliveries < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_qdeliveries_deliveries, :cache_search, :text
  end
end
