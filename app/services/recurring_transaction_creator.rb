class RecurringTransactionCreator
  attr_reader :account, :base_params, :amount, :months_count, :frequency

  def initialize(account:, base_params:, amount:, months_count: 12, frequency: "monthly")
    @account = account
    @base_params = base_params.to_h.symbolize_keys
    @amount = parse_amount(amount)
    @months_count = [ [ months_count.to_i, 1 ].max, 12 ].min
    @frequency = %w[weekly monthly yearly].include?(frequency.to_s) ? frequency.to_s : "monthly"
  end

  def call
    start_date = parse_date(base_params[:date]) || parse_date(base_params[:start_date]) || Date.current
    start_competence = parse_date(base_params[:competence_date]) || start_date

    card = nil
    if base_params[:credit_card_id].present?
      card = account.credit_cards.find_by(id: base_params[:credit_card_id])
    end

    category_id = base_params[:category_id].presence || account.categories.first&.id
    supplier_id = base_params[:supplier_id].presence || account.suppliers.first&.id

    created_txs = []

    ActiveRecord::Base.transaction do
      recurring_rule = account.recurring_transactions.create!(
        description: base_params[:description],
        amount: amount,
        transaction_type: base_params[:transaction_type] || "expense",
        frequency: frequency,
        start_date: start_date,
        category_id: category_id,
        supplier_id: supplier_id,
        cost_center_id: base_params[:cost_center_id],
        bank_account_id: base_params[:bank_account_id],
        credit_card_id: base_params[:credit_card_id],
        is_refund: base_params[:is_refund] || false,
        active: true
      )

      (1..months_count).each do |i|
        step = i - 1
        tx_date = case frequency
                  when "weekly" then start_date + step.weeks
                  when "yearly" then start_date >> (step * 12)
                  else start_date >> step
                  end

        comp_date = if card.present?
                      card.invoice_competence_for(tx_date)
                    else
                      case frequency
                      when "weekly" then start_competence + step.weeks
                      when "yearly" then start_competence >> (step * 12)
                      else start_competence >> step
                      end
                    end

        tx_status = if i == 1
                      base_params[:status].presence || (tx_date <= Date.current ? "realized" : "pending")
                    else
                      "pending"
                    end

        tx = account.transactions.create!(
          description: base_params[:description],
          amount: amount,
          date: tx_date,
          competence_date: comp_date,
          transaction_type: base_params[:transaction_type] || "expense",
          category_id: category_id,
          supplier_id: supplier_id,
          cost_center_id: base_params[:cost_center_id],
          bank_account_id: base_params[:bank_account_id],
          credit_card_id: base_params[:credit_card_id],
          is_refund: base_params[:is_refund] || false,
          status: tx_status,
          recurring_transaction: recurring_rule
        )

        created_txs << tx
      end
    end

    created_txs
  rescue StandardError => e
    Rails.logger.error("RecurringTransactionCreator Error: #{e.message}")
    nil
  end

  private

  def parse_amount(val)
    if val.is_a?(String)
      str = val.strip.gsub(/[R$\s]/, "")
      if str.include?(",") && str.include?(".")
        str.tr(".", "").tr(",", ".").to_f
      elsif str.include?(",")
        str.tr(",", ".").to_f
      else
        str.to_f
      end
    else
      val.to_f
    end
  end

  def parse_date(val)
    TransactionImporterService.parse_date(val)
  end
end
