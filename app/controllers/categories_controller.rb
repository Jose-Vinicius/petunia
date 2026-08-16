class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: [ :edit, :update, :destroy ]

  def index
    scope = current_account.categories
    scope = scope.where("LOWER(name) LIKE ?", "%#{params[:search].downcase.strip}%") if params[:search].present?
    @categories = scope.order(default: :desc, name: :asc)
  end

  def new
    @category = current_account.categories.build
  end

  def create
    @category = current_account.categories.build(category_params)

    respond_to do |format|
      if @category.save
        format.html { redirect_to categories_path, notice: t("categories.create.success", name: @category.name) }
        format.json { render json: { id: @category.id, name: @category.name }, status: :created }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: { errors: @category.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: t("categories.update.success", name: @category.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @category.destroy
    redirect_to categories_path, notice: t("categories.destroy.success", name: @category.name)
  end

  private

  def set_category
    @category = current_account.categories.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to categories_path, alert: t("categories.errors.not_found")
  end

  def category_params
    params.require(:category).permit(:name)
  end
end
