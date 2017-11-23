module Erp
  module Qdeliveries
    module Backend
      class DeliveriesController < Erp::Backend::BackendController
        before_action :set_delivery, only: [:delivery_details, :archive, :unarchive, :status_delivered, :status_deleted, :show, :edit, :update, :destroy]
        before_action :set_deliveries, only: [:status_delivered_all, :status_deleted_all, :archive_all, :unarchive_all]

        # GET /deliveries
        def index
        end

        # POST /deliveries/list
        def list
          @deliveries = Delivery.search(params).paginate(:page => params[:page], :per_page => 10)

          render layout: nil
        end

        def delivery_details
          render layout: nil
        end

        # GET /deliveries/1
        def show
        end

        # GET /deliveries/new
        def new
          @delivery = Delivery.new
          @delivery.date = Time.now
          @delivery.delivery_type = params[:delivery_type].to_s if params[:delivery_type].present?
          @delivery.employee_id = current_user.id

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

          @delivery.fill_details(params.to_unsafe_hash[:details])

          if @delivery.save
            if request.xhr?
              render json: {
                status: 'success',
                text: @delivery.code,
                value: @delivery.id
              }
            else
              redirect_to erp_qdeliveries.backend_deliveries_path, notice: t('.success')
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
              redirect_to erp_qdeliveries.backend_deliveries_path, notice: t('.success')
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
            params.fetch(:delivery, {}).permit(:code, :date, :delivery_type, :note, :employee_id, :customer_id, :supplier_id)
          end
      end
    end
  end
end
