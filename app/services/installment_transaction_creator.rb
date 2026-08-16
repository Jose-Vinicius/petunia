class InstallmentTransactionCreator
  def initialize(account:, base_params:, installments_count: nil, total_installments: nil, current_installment: 1, amount_per_installment: nil, total_amount: nil)
    @account = account
    @base_params = base_params.to_h.symbolize_keys
    @total_installments = (total_installments || installments_count).to_i
    @current_installment = [ current_installment.to_i, 1 ].max

    raw_amount = (amount_per_installment || total_amount).to_f

    if raw_amount > 0
      if @current_installment > 1
        @amount_per_installment = raw_amount
      else
        @total_amount = raw_amount
      end
    end
  end

  def call
    return nil if @total_installments < 2 || @current_installment > @total_installments
    return nil if @amount_per_installment.nil? && (@total_amount.nil? || @total_amount <= 0)

    group_id = SecureRandom.uuid
    base_date = parse_date(@base_params[:date]) || Date.current
    credit_card = @account.credit_cards.find_by(id: @base_params[:credit_card_id]) if @base_params[:credit_card_id].present?

    initial_competence = parse_date(@base_params[:competence_date]) ||
                         (credit_card.present? ? credit_card.invoice_competence_for(base_date) : base_date)

    base_description = @base_params[:description].to_s.gsub(/\s*\(\d+\/\d+\)\z/, "")
    created_transactions = []

    Transaction.transaction do
      if @amount_per_installment.present?
        (@current_installment..@total_installments).each do |i|
          month_offset = i - @current_installment
          comp_date = initial_competence >> month_offset
          tx_date = base_date

          tx = @account.transactions.build(@base_params.merge(
            amount: @amount_per_installment,
            date: tx_date,
            competence_date: comp_date,
            description: "#{base_description} (#{i}/#{@total_installments})",
            installment_group_id: group_id,
            installment_number: i,
            total_installments: @total_installments
          ))

          tx.save!
          created_transactions << tx
        end
      else
        total_cents = (@total_amount * 100).round
        per_installment_cents = total_cents / @total_installments
        remainder_cents = total_cents % @total_installments

        (1..@total_installments).each do |i|
          cents = per_installment_cents + (i == 1 ? remainder_cents : 0)
          amount = (cents / 100.0).round(2)

          comp_date = initial_competence >> (i - 1)
          tx_date = base_date

          tx = @account.transactions.build(@base_params.merge(
            amount: amount,
            date: tx_date,
            competence_date: comp_date,
            description: "#{base_description} (#{i}/#{@total_installments})",
            installment_group_id: group_id,
            installment_number: i,
            total_installments: @total_installments
          ))

          tx.save!
          created_transactions << tx
        end
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
