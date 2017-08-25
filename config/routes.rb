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
				end
			end
		end
	end
end