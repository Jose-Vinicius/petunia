class CreditCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_credit_card, only: [ :edit, :update, :destroy ]

  def index
    @credit_cards = current_account.credit_cards.includes(:bank_account)
  end

  def new
    @credit_card = current_account.credit_cards.build
  end

  def create
    @credit_card = current_account.credit_cards.build(credit_card_params)

    if @credit_card.save
      redirect_to credit_cards_path, notice: t("credit_cards.create.success", name: @credit_card.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @credit_card.update(credit_card_params)
      redirect_to credit_cards_path, notice: t("credit_cards.update.success", name: @credit_card.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @credit_card.destroy
    redirect_to credit_cards_path, notice: t("credit_cards.destroy.success", name: @credit_card.name)
  end

  private

  def set_credit_card
    @credit_card = current_account.credit_cards.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to credit_cards_path, alert: t("credit_cards.errors.not_found")
  end

  def credit_card_params
    params.require(:credit_card).permit(:name, :limit, :bank_account_id)
  end
end
