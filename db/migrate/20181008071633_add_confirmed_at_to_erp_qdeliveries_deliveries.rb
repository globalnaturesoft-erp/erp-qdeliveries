class AddConfirmedAtToErpQdeliveriesDeliveries < ActiveRecord::Migration[5.1]
  def change
    add_column :erp_qdeliveries_deliveries, :confirmed_at, :datetime
  end
end
