Erp::Qdeliveries::Engine.routes.draw do
  scope "(:locale)", locale: /en|vi/ do
		namespace :backend, module: "backend", path: "backend/qdeliveries" do
			resources :deliveries do
				collection do
					post 'list'
					get 'dataselect'
					delete 'delete_all'
					put 'status_delivered'
					put 'status_delivered_all'
					put 'status_deleted'
					put 'status_deleted_all'
					put 'archive'
					put 'unarchive'
					put 'archive_all'
					put 'unarchive_all'
					get 'delivery_details'
					post 'show_list'
					get 'pdf'
				end
			end
			
			get 'sales_orders' => 'sales#sales_orders', as: :sales_orders
			post 'sales_orders_listing' => 'sales#sales_orders_listing', as: :sales_orders_listing
			get 'sales_order_details' => 'sales#sales_order_details', as: :sales_order_details
			get 'deliveries_sales' => 'sales#deliveries_sales', as: :deliveries_sales

			get 'purchases_orders' => 'purchases#purchases_orders', as: :purchases_orders
			post 'purchases_orders_listing' => 'purchases#purchases_orders_listing', as: :purchases_orders_listing
			get 'purchases_order_details' => 'purchases#purchases_order_details', as: :purchases_order_details
			get 'deliveries_purchases' => 'purchases#deliveries_purchases', as: :deliveries_purchases			

			resources :delivery_details do
				collection do
					get 'form_detail'
					post 'form_detail'
				end
			end
		end
	end
end
