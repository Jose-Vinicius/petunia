class InstallmentTransactionCreator
  def initialize(account:, base_params:, installments_count:, total_amount:)
    @account = account
    @base_params = base_params.to_h.symbolize_keys
    @installments_count = installments_count.to_i
    @total_amount = total_amount.to_f
  end

  def call
    return nil if @installments_count < 2 || @total_amount <= 0

    group_id = SecureRandom.uuid
    total_cents = (@total_amount * 100).round
    per_installment_cents = total_cents / @installments_count
    remainder_cents = total_cents % @installments_count

    created_transactions = []
    base_date = parse_date(@base_params[:date]) || Date.current
    credit_card = @account.credit_cards.find_by(id: @base_params[:credit_card_id]) if @base_params[:credit_card_id].present?

    initial_competence = if credit_card.present?
                           credit_card.invoice_competence_for(base_date)
                         else
                           parse_date(@base_params[:competence_date]) || base_date
                         end

    base_description = @base_params[:description].to_s.gsub(/\s*\(\d+\/\d+\)\z/, "")

    Transaction.transaction do
      (1..@installments_count).each do |i|
        cents = per_installment_cents + (i == 1 ? remainder_cents : 0)
        amount = (cents / 100.0).round(2)

        comp_date = initial_competence >> (i - 1)
        tx_date = credit_card.present? ? base_date : (base_date >> (i - 1))

        tx = @account.transactions.build(@base_params.merge(
          amount: amount,
          date: tx_date,
          competence_date: comp_date,
          description: "#{base_description} (#{i}/#{@installments_count})",
          installment_group_id: group_id,
          installment_number: i,
          total_installments: @installments_count
        ))

        tx.save!
        created_transactions << tx
      end
    end

    created_transactions
  rescue ActiveRecord::RecordInvalid => e
    nil
  end

  private

  def parse_date(val)
    return nil if val.blank?
    val.is_a?(Date) ? val : Date.parse(val.to_s) rescue nil
  end
end
