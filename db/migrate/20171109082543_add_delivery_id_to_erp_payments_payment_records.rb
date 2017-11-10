class AddDeliveryIdToErpPaymentsPaymentRecords < ActiveRecord::Migration[5.1]
  def change
    add_reference :erp_payments_payment_records, :delivery, index: true, references: :erp_qdeliveries_deliveries
  end
end
