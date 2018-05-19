module Erp
  module Qdeliveries
    module ApplicationHelper
      def qdelivery_dropdown_actions(delivery)
        actions = []
        
        actions << {
          text: '<i class="fa fa-print"></i> '+t('.view_print'),
          url: erp_qdeliveries.backend_delivery_path(delivery),
          class: 'modal-link'
        } if can? :print, delivery
        
        actions << {
          text: '<i class="fa fa-edit"></i> '+t('.edit'),
          url: erp_qdeliveries.edit_backend_delivery_path(delivery)
        } if can? :update, delivery
        
        actions << {
          text: '<i class="fa fa-trash"></i> '+t('.set_delivered'),
          url: erp_qdeliveries.status_delivered_backend_deliveries_path(id: delivery),
          data_method: 'PUT',
          class: 'ajax-link'
        } if can? :set_delivered, delivery
        
        actions << { divider: true } if can? :set_deleted, delivery
        
        actions << {
          text: '<i class="fa fa-trash"></i> '+t('.set_deleted'),
          url: erp_qdeliveries.status_deleted_backend_deliveries_path(id: delivery),
          data_method: 'PUT',
          class: 'ajax-link',
          data_confirm: t('delete_confirm')
        } if can? :set_deleted, delivery
        
        erp_datalist_row_actions(
          actions
        )
      end

      # Sales order dropdown actions
      def sales_purchases_order_dropdown_actions(order)
        actions = []
        
        actions << {
          text: '<i class="fa fa-file-text-o"></i> '+t('.view'),
          url: erp_orders.backend_order_path(order),
          class: 'modal-link'
        }
        
        actions << {
          text: '<i class="icon-action-redo"></i> Xuất kho',
          url: erp_qdeliveries.new_backend_delivery_path(delivery_type: Erp::Qdeliveries::Delivery::TYPE_SALES_EXPORT, order_id: order.id),
        } if can? :sales_export, order
        
        actions << {
          text: '<i class="icon-action-redo"></i> Nhập kho',
          url: erp_qdeliveries.new_backend_delivery_path(delivery_type: Erp::Qdeliveries::Delivery::TYPE_PURCHASE_IMPORT, order_id: order.id),
        } if can? :purchase_import, order
        
        erp_datalist_row_actions(
          actions
        )
      end
      
      # order link helper
      def qdelivery_link(delivery, text=nil)
        text = text.nil? ? delivery.code : text
        raw "<a href='#{erp_qdeliveries.backend_delivery_path(delivery)}' class='modal-link'>#{text}</a>"
      end

    end
  end
end
