Erp::Ability.class_eval do
  def qdeliveries_ability(user)

    # Cancan for Order
    can :read, Erp::Qdeliveries::Delivery

    can :print, Erp::Qdeliveries::Delivery do |delivery|
      delivery
    end

    can :update, Erp::Qdeliveries::Delivery do |delivery|
      delivery
    end

    can :delete, Erp::Qdeliveries::Delivery do |delivery|
      delivery
    end

    can :pay_sales_import, Erp::Qdeliveries::Delivery do |delivery|
      if delivery.payment_for == Erp::Qdeliveries::Delivery::PAYMENT_FOR_ORDER
        delivery.remain_amount > 0
      end
    end

    can :receive_sales_import, Erp::Qdeliveries::Delivery do |delivery|
      if delivery.payment_for == Erp::Qdeliveries::Delivery::PAYMENT_FOR_ORDER
        delivery.remain_amount < 0
      end
    end
  end
end
