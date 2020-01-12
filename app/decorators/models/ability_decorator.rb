Erp::Ability.class_eval do
  def qdeliveries_ability(user)
    
    can :read, Erp::Qdeliveries::Delivery

    can :print, Erp::Qdeliveries::Delivery do |delivery|
      delivery.is_delivered? and
      (
        (delivery.is_sales_export? and user.get_permission(:inventory, :qdeliveries, :sales_export, :print) == 'yes') or
        (delivery.is_sales_import? and user.get_permission(:inventory, :qdeliveries, :sales_import, :print) == 'yes') or
        (delivery.is_purchase_import? and user.get_permission(:inventory, :qdeliveries, :purchase_import, :print) == 'yes') or
        (delivery.is_purchase_export? and user.get_permission(:inventory, :qdeliveries, :purchase_export, :print) == 'yes') or
        (delivery.is_custom_import? and user.get_permission(:inventory, :qdeliveries, :custom_import, :print) == 'yes') or
        (delivery.is_custom_export? and user.get_permission(:inventory, :qdeliveries, :custom_export, :print) == 'yes')
      )
    end
    
    can :create, Erp::Qdeliveries::Delivery do |delivery|
      (delivery.is_sales_export? and user.get_permission(:inventory, :qdeliveries, :sales_export, :create) == 'yes') or
      (delivery.is_sales_import? and user.get_permission(:inventory, :qdeliveries, :sales_import, :create) == 'yes') or
      (delivery.is_purchase_import? and user.get_permission(:inventory, :qdeliveries, :purchase_import, :create) == 'yes') or
      (delivery.is_purchase_export? and user.get_permission(:inventory, :qdeliveries, :purchase_export, :create) == 'yes') or
      (delivery.is_custom_import? and user.get_permission(:inventory, :qdeliveries, :custom_import, :create) == 'yes') or
      (delivery.is_custom_export? and user.get_permission(:inventory, :qdeliveries, :custom_export, :create) == 'yes')
    end

    can :update, Erp::Qdeliveries::Delivery do |delivery|
      !delivery.is_deleted? and
      (
        # sale export
        (
          delivery.is_sales_export? and
          (
            user.get_permission(:inventory, :qdeliveries, :sales_export, :update) == 'yes' or
            (
              user.get_permission(:inventory, :qdeliveries, :sales_export, :update) == 'in_day' and
              (delivery.confirmed_at.nil? or (Time.now < delivery.confirmed_at.end_of_day and delivery.is_delivered?))
            )
          )
        ) or
        
        # sale import
        (
          delivery.is_sales_import? and
          (
            user.get_permission(:inventory, :qdeliveries, :sales_import, :update) == 'yes' or
            (
              user.get_permission(:inventory, :qdeliveries, :sales_import, :update) == 'in_day' and
              (delivery.confirmed_at.nil? or (Time.now < delivery.confirmed_at.end_of_day and delivery.is_delivered?))
            )
          )
        ) or
        
        # purchase import
        (
          delivery.is_purchase_import? and
          (
            user.get_permission(:inventory, :qdeliveries, :purchase_import, :update) == 'yes' or
            (
              user.get_permission(:inventory, :qdeliveries, :purchase_import, :update) == 'in_day' and
              (delivery.confirmed_at.nil? or (Time.now < delivery.confirmed_at.end_of_day and delivery.is_delivered?))
            )
          )
        ) or
        
        # purchase export
        (
          delivery.is_purchase_export? and
          (
            user.get_permission(:inventory, :qdeliveries, :purchase_export, :update) == 'yes' or
            (
              user.get_permission(:inventory, :qdeliveries, :purchase_export, :update) == 'in_day' and
              (delivery.confirmed_at.nil? or (Time.now < delivery.confirmed_at.end_of_day and delivery.is_delivered?))
            )
          )
        ) or
        
        # custom import
        (
          delivery.is_custom_import? and
          (
            user.get_permission(:inventory, :qdeliveries, :custom_import, :update) == 'yes' or
            (
              user.get_permission(:inventory, :qdeliveries, :custom_import, :update) == 'in_day' and
              (delivery.confirmed_at.nil? or (Time.now < delivery.confirmed_at.end_of_day and delivery.is_delivered?))
            )
          )
        ) or
        
        # custom export
        (
          delivery.is_custom_export? and
          (
            user.get_permission(:inventory, :qdeliveries, :custom_export, :update) == 'yes' or
            (
              user.get_permission(:inventory, :qdeliveries, :custom_export, :update) == 'in_day' and
              (delivery.confirmed_at.nil? or (Time.now < delivery.confirmed_at.end_of_day and delivery.is_delivered?))
            )
          )
        )
      )
    end

    can :set_delivered, Erp::Qdeliveries::Delivery do |delivery|
      delivery.is_pending? and
      (
        #(delivery.is_sales_export? and user.get_permission(:inventory, :qdeliveries, :sales_export, :approve) == 'yes') or
        (delivery.is_sales_import? and user.get_permission(:inventory, :qdeliveries, :sales_import, :approve) == 'yes')
        #or
        #(delivery.is_purchase_import? and user.get_permission(:inventory, :qdeliveries, :purchase_import, :approve) == 'yes') or
        #(delivery.is_purchase_export? and user.get_permission(:inventory, :qdeliveries, :purchase_export, :approve) == 'yes') or
        #(delivery.is_custom_import? and user.get_permission(:inventory, :qdeliveries, :custom_import, :approve) == 'yes') or
        #(delivery.is_custom_export? and user.get_permission(:inventory, :qdeliveries, :custom_export, :approve) == 'yes')
      )
    end

    can :set_deleted, Erp::Qdeliveries::Delivery do |delivery|
      !delivery.is_deleted? and
      (
        (delivery.is_sales_export? and user.get_permission(:inventory, :qdeliveries, :sales_export, :delete) == 'yes') or
        (delivery.is_sales_import? and user.get_permission(:inventory, :qdeliveries, :sales_import, :delete) == 'yes') or
        (delivery.is_purchase_import? and user.get_permission(:inventory, :qdeliveries, :purchase_import, :delete) == 'yes') or
        (delivery.is_purchase_export? and user.get_permission(:inventory, :qdeliveries, :purchase_export, :delete) == 'yes') or
        (delivery.is_custom_import? and user.get_permission(:inventory, :qdeliveries, :custom_import, :delete) == 'yes') or
        (delivery.is_custom_export? and user.get_permission(:inventory, :qdeliveries, :custom_export, :delete) == 'yes')
      )
    end
    
    # dieu kien thanh toan cho don hang ban bi tra lai (hoan kho theo don hang)
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
