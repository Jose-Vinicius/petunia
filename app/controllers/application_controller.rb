class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_account

  def current_account
    return nil unless user_signed_in?

    @current_account ||= find_current_account
  end

  private

  def find_current_account
    account = current_user.accounts.find_by(id: session[:current_account_id]) if session[:current_account_id].present?
    account ||= current_user.accounts.first

    session[:current_account_id] = account&.id
    account
  end
end
