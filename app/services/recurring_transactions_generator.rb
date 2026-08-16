class RecurringTransactionsGenerator
  attr_reader :account, :target_months

  def initialize(account:, target_months: 12)
    @account = account
    @target_months = [ [ target_months.to_i, 1 ].max, 12 ].min
  end

  def call
    generated_count = 0

    account.recurring_transactions.active.find_each do |rule|
      card = rule.credit_card

      (0...target_months).each do |m|
        target_date = case rule.frequency
                      when "weekly" then rule.start_date + m.weeks
                      when "yearly" then rule.start_date >> (m * 12)
                      else rule.start_date >> m
                      end

        next if target_date < rule.start_date
        next if rule.end_date.present? && target_date > rule.end_date

        comp_date = if card.present?
                      card.invoice_competence_for(target_date)
                    else
                      case rule.frequency
                      when "weekly" then rule.start_date + m.weeks
                      when "yearly" then rule.start_date >> (m * 12)
                      else rule.start_date >> m
                      end
                    end

        # Check if transaction for this month already exists
        start_of_month = target_date.beginning_of_month
        end_of_month = target_date.end_of_month

        exists = rule.transactions.where(date: start_of_month..end_of_month).exists?
        next if exists

        status_val = target_date <= Date.current ? "realized" : "pending"

        account.transactions.create!(
          description: rule.description,
          amount: rule.amount,
          date: target_date,
          competence_date: comp_date,
          transaction_type: rule.transaction_type,
          category: rule.category,
          supplier: rule.supplier,
          cost_center: rule.cost_center,
          bank_account: rule.bank_account,
          credit_card: rule.credit_card,
          is_refund: rule.is_refund,
          status: status_val,
          recurring_transaction: rule
        )

        generated_count += 1
      end
    end

    generated_count
  end
end
