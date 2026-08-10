class CostCentersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cost_center, only: [ :edit, :update, :destroy ]

  def index
    @cost_centers = current_account.cost_centers.order(default: :desc, name: :asc)
  end

  def new
    @cost_center = current_account.cost_centers.build
  end

  def create
    @cost_center = current_account.cost_centers.build(cost_center_params)

    if @cost_center.save
      redirect_to cost_centers_path, notice: t("cost_centers.create.success", name: @cost_center.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @cost_center.update(cost_center_params)
      redirect_to cost_centers_path, notice: t("cost_centers.update.success", name: @cost_center.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @cost_center.destroy
    redirect_to cost_centers_path, notice: t("cost_centers.destroy.success", name: @cost_center.name)
  end

  private

  def set_cost_center
    @cost_center = current_account.cost_centers.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to cost_centers_path, alert: t("cost_centers.errors.not_found")
  end

  def cost_center_params
    params.require(:cost_center).permit(:name)
  end
end
