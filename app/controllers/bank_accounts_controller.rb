class BankAccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bank_account, only: [ :edit, :update, :destroy ]

  def index
    @bank_accounts = current_account.bank_accounts
  end

  def new
    @bank_account = current_account.bank_accounts.build
  end

  def create
    @bank_account = current_account.bank_accounts.build(bank_account_params)

    if @bank_account.save
      redirect_to bank_accounts_path, notice: t("bank_accounts.create.success", name: @bank_account.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @bank_account.update(bank_account_params)
      redirect_to bank_accounts_path, notice: t("bank_accounts.update.success", name: @bank_account.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @bank_account.destroy
    redirect_to bank_accounts_path, notice: t("bank_accounts.destroy.success", name: @bank_account.name)
  end

  private

  def set_bank_account
    @bank_account = current_account.bank_accounts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to bank_accounts_path, alert: t("bank_accounts.errors.not_found")
  end

  def bank_account_params
    params.require(:bank_account).permit(:name)
  end
end
