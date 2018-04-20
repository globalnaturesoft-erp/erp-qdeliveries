Erp::Ability.class_eval do
  def qdeliveries_ability(user)
    
    can :read, Erp::Qdeliveries::Delivery

    can :print, Erp::Qdeliveries::Delivery do |delivery|
      delivery.is_delivered?
    end

    can :update, Erp::Qdeliveries::Delivery do |delivery|
      delivery
    end

    can :set_delivered, Erp::Qdeliveries::Delivery do |delivery|
      delivery.is_deleted?
    end

    can :set_deleted, Erp::Qdeliveries::Delivery do |delivery|
      delivery.is_delivered?
    end

    can :pay_sales_import, Erp::Qdeliveries::Delivery do |delivery|
      if delivery.is_delivered?
        if delivery.payment_for == Erp::Qdeliveries::Delivery::PAYMENT_FOR_ORDER
          delivery.remain_amount > 0
        end
      end
    end

    can :receive_sales_import, Erp::Qdeliveries::Delivery do |delivery|
      if delivery.is_delivered?
        if delivery.payment_for == Erp::Qdeliveries::Delivery::PAYMENT_FOR_ORDER
          delivery.remain_amount < 0
        end
      end
    end
  end
end
