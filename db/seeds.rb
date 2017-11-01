users = Erp::User.all

status = [Erp::Qdeliveries::Delivery::STATUS_DELIVERED,
          Erp::Qdeliveries::Delivery::STATUS_DELETED]

owner = Erp::Contacts::Contact.get_main_contact
contacts = Erp::Contacts::Contact.where('id != ?', owner.id)

delivery_type = [Erp::Qdeliveries::Delivery::TYPE_WAREHOUSE_IMPORT,
         Erp::Qdeliveries::Delivery::TYPE_WAREHOUSE_EXPORT,
         Erp::Qdeliveries::Delivery::TYPE_CUSTOMER_IMPORT,
         Erp::Qdeliveries::Delivery::TYPE_MANUFACTURER_EXPORT]

keys = ['XK', 'NK', 'TH', 'THN']

# Orders
Erp::Qdeliveries::Delivery.all.destroy_all
(1..30).each do |num|
  key = keys[rand(keys.count)]
  contact = contacts.order("RANDOM()").first
  delivery = Erp::Qdeliveries::Delivery.create(
    code: key + num.to_s.rjust(5, '0'),
    date: rand((Time.current - 5.day)..Time.current),
    employee_id: users.order("RANDOM()").first.id,
    supplier_id: (key==keys[0]) ? owner.id : contact.id,
    customer_id: (key==keys[0]) ? contact.id : owner.id,
    delivery_type: delivery_type[rand(delivery_type.count)],
    status: status[rand(status.count)],
    creator_id: users.order("RANDOM()").first.id
  )
  puts '==== Q-delivery ' +num.ordinalize+ ' start ('+delivery.code+') ===='
  wareshouse = Erp::Warehouses::Warehouse.where(id: Erp::Warehouses::Warehouse.pluck(:id).sample(2))
  Erp::Orders::OrderDetail.where(id: Erp::Orders::OrderDetail.pluck(:id).sample(rand(1..20))).each do |order_detail|
    delivery_detail = Erp::Qdeliveries::DeliveryDetail.create(
      order_detail_id: order_detail.id,
      delivery_id: delivery.id,
      quantity: rand(1..order_detail.quantity),
      price: delivery.delivery_type == Erp::Qdeliveries::Delivery::TYPE_CUSTOMER_IMPORT ? rand(0..(order_detail.price/1000))*1000 : nil,
      warehouse_id: wareshouse.second.id
    )
    puts '====>>>>>> Delivery detail ' +num.ordinalize+ ' complete ('+delivery.code+') ===='
  end
  puts '==== Complete ===='
end