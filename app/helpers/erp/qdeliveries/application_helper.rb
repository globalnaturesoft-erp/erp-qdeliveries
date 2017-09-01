module Erp
  module Qdeliveries
    module ApplicationHelper
      def qdelivery_dropdown_actions(delivery)
        actions = []
        actions << {
          text: '<i class="fa fa-edit"></i> '+t('.edit'),
          url: erp_qdeliveries.edit_backend_delivery_path(delivery)
        }
        actions << { divider: true }
        actions << {
          text: '<i class="fa fa-trash"></i> '+t('.action_deleted'),
          url: erp_qdeliveries.status_deleted_backend_deliveries_path(id: delivery),
          data_method: 'PUT',
          class: 'ajax-link',
          data_confirm: t('delete_confirm')
        }        
        erp_datalist_row_actions(
          actions
        )
      end
      
      # Sales order dropdown actions
      def sales_purchases_order_dropdown_actions(order)
        actions = []
        actions << {
          text: '<i class="fa fa-file-text-o"></i> '+t('.view'),
          url: erp_orders.backend_order_path(order)
        }                      
        erp_datalist_row_actions(
          actions
        )
      end
      
    end
  end
end
