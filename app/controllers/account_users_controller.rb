class AccountUsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_account
  before_action :ensure_owner!

  def index
    @account_users = @account.account_users.includes(:user)
  end

  def create
    email = params[:email].to_s.strip.downcase
    role = params[:role].presence || "member"
    password = params[:password].to_s.strip

    if email.blank?
      flash.now[:alert] = t("account_users.errors.email_blank")
      @account_users = @account.account_users.includes(:user)
      render :index, status: :unprocessable_content and return
    end

    user = User.find_by(email: email)

    if user.nil?
      if password.blank? || password.length < 6
        flash.now[:alert] = t("account_users.errors.password_required")
        @account_users = @account.account_users.includes(:user)
        render :index, status: :unprocessable_content and return
      end

      user = User.new(email: email, password: password, password_confirmation: password)

      unless user.save
        flash.now[:alert] = user.errors.full_messages.join(", ")
        @account_users = @account.account_users.includes(:user)
        render :index, status: :unprocessable_content and return
      end
    end

    if @account.account_users.exists?(user_id: user.id)
      redirect_to account_account_users_path(@account), alert: t("account_users.errors.already_member", email: email)
    else
      @account.account_users.create!(user: user, role: role)
      redirect_to account_account_users_path(@account), notice: t("account_users.create.success", email: email)
    end
  end

  def destroy
    account_user = @account.account_users.find(params[:id])

    if account_user.role == "owner" && @account.account_users.where(role: "owner").count <= 1
      redirect_to account_account_users_path(@account), alert: t("account_users.destroy.last_owner_error")
    else
      account_user.destroy
      redirect_to account_account_users_path(@account), notice: t("account_users.destroy.success")
    end
  end

  private

  def set_account
    @account = current_user.accounts.find(params[:account_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to accounts_path, alert: t("accounts.switch.error")
  end

  def ensure_owner!
    account_user = current_user.account_users.find_by(account: @account)
    unless account_user&.role == "owner"
      redirect_to accounts_path, alert: t("account_users.errors.unauthorized")
    end
  end
end
