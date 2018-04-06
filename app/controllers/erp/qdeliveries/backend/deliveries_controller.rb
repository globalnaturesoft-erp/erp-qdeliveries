module Erp
  module Qdeliveries
    module Backend
      class DeliveriesController < Erp::Backend::BackendController
        before_action :set_delivery, only: [:xls, :delivery_details, :archive, :unarchive, :status_delivered, :status_deleted,
                                            :pdf, :show, :show_list, :edit, :update, :destroy]
        before_action :set_deliveries, only: [:status_delivered_all, :status_deleted_all, :archive_all, :unarchive_all]

        # GET /deliveries
        def index
        end

        # POST /deliveries/list
        def list
          @deliveries = Delivery.search(params).paginate(:page => params[:page], :per_page => 20)

          render layout: nil
        end

        def delivery_details
          @delivery_details = @delivery.delivery_details#.paginate(:page => params[:page], :per_page => 10)
          render layout: nil
        end

        # GET /deliveries/1
        def show
          respond_to do |format|
            format.html
            format.pdf do
              render pdf: "show_list",
                layout: 'erp/backend/pdf'
            end
          end
        end

        # GET /orders/1
        def pdf
          #authorize! :read, @delivery

          respond_to do |format|
            format.html
            format.pdf do
              if @delivery.delivery_details.count < 8
                render pdf: "#{@delivery.code}",
                  title: "#{@delivery.code}",
                  layout: 'erp/backend/pdf',
                  page_size: 'A5',
                  orientation: 'Landscape',
                  margin: {
                    top: 7,                     # default 10 (mm)
                    bottom: 7,
                    left: 7,
                    right: 7
                  }
              else
                render pdf: "#{@delivery.code}",
                  title: "#{@delivery.code}",
                  layout: 'erp/backend/pdf',
                  page_size: 'A4',
                  margin: {
                    top: 7,                     # default 10 (mm)
                    bottom: 7,
                    left: 7,
                    right: 7
                  }
              end
            end
          end
        end

        # GET /deliveries/new
        def new
          @delivery = Delivery.new
          @delivery.date = Time.now
          @delivery.delivery_type = params[:delivery_type].to_s if params[:delivery_type].present?
          @delivery.payment_for = Erp::Qdeliveries::Delivery::PAYMENT_FOR_ORDER

          if params[:order_id].present?
            @order = Erp::Orders::Order.find(params[:order_id])
            @delivery.customer_id = @order.customer_id if @order.sales?
            @delivery.supplier_id = @order.supplier_id if @order.purchase?

            @order.order_details.each do |od|
              if !od.is_delivered?
                @delivery.delivery_details.build(
                  order_detail_id: od.id,
                  state_id: (Erp::Products::State.first.nil? ? nil : Erp::Products::State.first.id),
                  warehouse_id: @order.warehouse_id,
                  quantity: od.not_delivered_quantity,
                )
              end
            end
          end
        end

        # GET /deliveries/1/edit
        def edit
        end

        # POST /deliveries
        def create
          @delivery = Delivery.new(delivery_params)
          @delivery.creator = current_user
          @delivery.delivery_type = params[:delivery][:delivery_type]

          if @delivery.save
            @delivery.update_details(params.to_unsafe_hash[:details])

            if request.xhr?
              render json: {
                status: 'success',
                text: @delivery.code,
                value: @delivery.id
              }
            else
              if params.to_unsafe_hash[:save_print].present?
                redirect_to erp_qdeliveries.backend_delivery_path(@delivery), notice: t('.success')
              else
                redirect_to erp_qdeliveries.backend_deliveries_path, notice: t('.success')
              end
            end
          else
            logger.info(@delivery.errors.to_json)
            render :new
          end
        end

        # PATCH/PUT /deliveries/1
        def update
          if @delivery.update(delivery_params)
            # destroy detals not in form
            @delivery.update_details(params.to_unsafe_hash[:details])

            if request.xhr?
              render json: {
                status: 'success',
                text: @delivery.code,
                value: @delivery.id
              }
            else
              if params.to_unsafe_hash[:save_print].present?
                redirect_to erp_qdeliveries.backend_delivery_path(@delivery), notice: t('.success')
              else
                redirect_to erp_qdeliveries.backend_deliveries_path, notice: t('.success')
              end
            end
          else
            render :edit
          end
        end

        # DELETE /deliveries/1
        def destroy
          @delivery.destroy

          respond_to do |format|
            format.html { redirect_to erp_qdeliveries.backend_deliveries_path, notice: t('.success') }
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end

        # ARCHIVE /deliveries/archive?id=1
        def archive
          @delivery.archive

          respond_to do |format|
            format.html { redirect_to erp_qdeliveries.backend_deliveries_path, notice: t('.success') }
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end

        # UNARCHIVE /deliveries/unarchive?id=1
        def unarchive
          @delivery.unarchive

          respond_to do |format|
            format.html { redirect_to erp_qdeliveries.backend_deliveries_path, notice: t('.success') }
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end

        # STATUS DELIVERED /deliveries/status_delivered?id=1
        def status_delivered
          @delivery.status_delivered
          respond_to do |format|
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end

        # STATUS DELIVERED ALL /deliveries/status_delivered_all?ids=1,2,3
        def status_delivered_all
          @deliveries.status_delivered_all

          respond_to do |format|
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end

        # STATUS DELETED /deliveries/status_deleted?id=1
        def status_deleted
          @delivery.status_deleted
          respond_to do |format|
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end

        # STATUS DELETED ALL /deliveries/status_deleted_all?ids=1,2,3
        def status_deleted_all
          @deliveries.status_deleted_all

          respond_to do |format|
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end

        # DELETE ALL /deliveries/delete_all?ids=1,2,3
        def delete_all
          @deliveries.destroy_all

          respond_to do |format|
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end

        # ARCHIVE ALL /deliveries/archive_all?ids=1,2,3
        def archive_all
          @deliveries.archive_all

          respond_to do |format|
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end

        # UNARCHIVE ALL /deliveries/unarchive_all?ids=1,2,3
        def unarchive_all
          @deliveries.unarchive_all

          respond_to do |format|
            format.json {
              render json: {
                'message': t('.success'),
                'type': 'success'
              }
            }
          end
        end

        # DATASELECT
        def dataselect
          respond_to do |format|
            format.json {
              render json: Delivery.dataselect(params[:keyword], params)
            }
          end
        end

        def xls
          respond_to do |format|
            format.xlsx
          end
        end

        # POST /deliveries/1
        def import_file
          if params[:id].present?
            @delivery = Delivery.find(params[:id])
            @delivery.assign_attributes(delivery_params)

            if params[:import_file].present?
              @delivery.import(params[:import_file])
            end

            render :edit
          else
            @delivery = Delivery.new(delivery_params)

            if params[:import_file].present?
              @delivery.import(params[:import_file])
            end

            render :new
          end
        end
        
        def ajax_address_field
          @customer = Erp::Contacts::Contact.where(id: params[:datas][0]).first
          @supplier = Erp::Contacts::Contact.where(id: params[:datas][1]).first

          if @customer.present?
            @address = view_context.display_contact_address(@customer)
          end
          
          if @supplier.present?
            @address = view_context.display_contact_address(@supplier)
          end
          
          @is_edit = params[:delivery_id].present? ? true : false
          @new_address = @address
          @address = params[:address] if params[:address].present?
        end
        
        def ajax_employee_field
          @customer = Erp::Contacts::Contact.where(id: params[:datas][0]).first
          @supplier = Erp::Contacts::Contact.where(id: params[:datas][1]).first
          
          @employee = Erp::User.new
          if params[:employee_id].present?
            @employee = Erp::User.find(params[:employee_id])
          end
          
          if @customer.present? and @customer.salesperson_id.present?
            @employee = Erp::User.find(@customer.salesperson_id)
          end
          
          if @supplier.present? and @supplier.salesperson_id.present?
            @employee = Erp::User.find(@supplier.salesperson_id)
          end
          
          render layout: false
        end

        private
          # Use callbacks to share common setup or constraints between actions.
          def set_delivery
            @delivery = Delivery.find(params[:id])
          end

          def set_deliveries
            @deliveries = Delivery.where(id: params[:ids])
          end

          # Only allow a trusted parameter "white list" through.
          def delivery_params
            params.fetch(:delivery, {}).permit(:code, :date, :delivery_type, :note, :address,
                                               :employee_id, :customer_id, :supplier_id, :payment_for)
          end
      end
    end
  end
end
