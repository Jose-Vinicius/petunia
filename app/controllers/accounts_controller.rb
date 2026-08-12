class AccountsController < ApplicationController
  before_action :authenticate_user!

  def index
    @accounts = current_user.accounts
  end

  def new
    @account = Account.new
  end

  def create
    @account = Account.new(account_params)

    if @account.save
      current_user.account_users.create!(account: @account, role: "owner")
      session[:current_account_id] = @account.id
      redirect_to root_path, notice: t("accounts.create.success", name: @account.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  def switch
    account = current_user.accounts.find_by(id: params[:id])

    if account
      session[:current_account_id] = account.id
      redirect_back fallback_location: root_path, notice: t("accounts.switch.success", name: account.name)
    else
      redirect_back fallback_location: root_path, alert: t("accounts.switch.error")
    end
  end

  def reset_data
    account = current_user.accounts.find_by(id: params[:id])

    if account
      account_user = current_user.account_users.find_by(account: account)
      if account_user&.role == "owner"
        account.reset_data!
        redirect_to accounts_path, status: :see_other, notice: t("accounts.reset.success", name: account.name)
      else
        redirect_to accounts_path, status: :see_other, alert: t("accounts.reset.unauthorized")
      end
    else
      redirect_to accounts_path, status: :see_other, alert: t("accounts.reset.not_found")
    end
  end

  private

  def account_params
    params.require(:account).permit(:name)
  end
end
