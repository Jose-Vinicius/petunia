class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @start_date = Date.current.beginning_of_month
    @end_date = Date.current.end_of_month

    transactions_scope = current_account.transactions.where(date: @start_date..@end_date)

    @monthly_income = transactions_scope.income.sum(:amount)
    @monthly_expense = transactions_scope.expense.sum(:amount)
    @monthly_balance = @monthly_income - @monthly_expense

    # Total consolidated balance across all transactions in history
    @consolidated_balance = current_account.transactions.income.sum(:amount) - current_account.transactions.expense.sum(:amount)

    # Category breakdown (expenses)
    @category_expenses = transactions_scope.expense
                                             .joins(:category)
                                             .group("categories.name")
                                             .sum(:amount)
                                             .sort_by { |_name, total| -total }

    # Accounts summary
    @bank_accounts = current_account.bank_accounts.includes(:transactions)
    @credit_cards = current_account.credit_cards.includes(:transactions)

    # Recent transactions feed (last 5)
    @recent_transactions = current_account.transactions
                                          .includes(:category, :cost_center, :bank_account, :credit_card)
                                          .order(date: :desc, created_at: :desc)
                                          .limit(5)
  end
end
