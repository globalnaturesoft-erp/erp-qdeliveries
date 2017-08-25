class CreateErpQdeliveriesDeliveries < ActiveRecord::Migration[5.1]
  def change
    create_table :erp_qdeliveries_deliveries do |t|
      t.string :code
      t.datetime :date
      t.string :delivery_type
      t.text :note
      t.string :status, default: "delivered"
      t.boolean :archived, default: false
      t.references :customer, index: true, references: :erp_contacts_contacts
      t.references :supplier, index: true, references: :erp_contacts_contacts
      t.references :employee, index: true, references: :erp_users
      t.references :creator, index: true, references: :erp_users

      t.timestamps
    end
  end
end
