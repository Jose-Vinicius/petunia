class SuppliersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_supplier, only: [ :edit, :update, :destroy ]

  def index
    @suppliers = current_account.suppliers.order(:name)
  end

  def new
    @supplier = current_account.suppliers.build
  end

  def create
    @supplier = current_account.suppliers.build(supplier_params)

    respond_to do |format|
      if @supplier.save
        format.html { redirect_to suppliers_path, notice: t("suppliers.create.success", name: @supplier.name) }
        format.json { render json: { id: @supplier.id, name: @supplier.name }, status: :created }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: { errors: @supplier.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def edit
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to suppliers_path, notice: t("suppliers.update.success", name: @supplier.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @supplier.destroy
      redirect_to suppliers_path, notice: t("suppliers.destroy.success", name: @supplier.name)
    else
      redirect_to suppliers_path, alert: @supplier.errors.full_messages.to_sentence
    end
  end

  private

  def set_supplier
    @supplier = current_account.suppliers.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to suppliers_path, alert: t("suppliers.errors.not_found")
  end

  def supplier_params
    params.require(:supplier).permit(:name)
  end
end
