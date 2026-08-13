require 'rails_helper'

RSpec.describe RecurringTransactionCreator, type: :service do
  let(:account) { create(:account) }
  let(:category) { account.categories.first }
  let(:supplier) { create(:supplier, account: account) }
  let(:bank_account) { create(:bank_account, account: account) }

  describe '#call' do
    it 'cria a regra de recorrência e projeta N lançamentos futuros com valor integral' do
      base_params = {
        description: "Aluguel Mensal",
        date: "01/08/2026",
        transaction_type: "expense",
        category_id: category.id,
        supplier_id: supplier.id,
        bank_account_id: bank_account.id
      }

      creator = described_class.new(
        account: account,
        base_params: base_params,
        amount: 900.00,
        months_count: 6
      )

      txs = creator.call
      expect(txs.size).to eq(6)
      expect(account.recurring_transactions.count).to eq(1)

      rule = account.recurring_transactions.first
      expect(rule.description).to eq("Aluguel Mensal")
      expect(rule.amount).to eq(900.00)

      # Cada movimentação deve ter o valor integral de 900.00
      expect(txs.pluck(:amount).uniq).to eq([900.00])
      expect(txs.pluck(:recurring_transaction_id).uniq).to eq([rule.id])

      # Verifica progressão das datas
      dates = txs.map(&:date)
      expect(dates).to eq([
        Date.new(2026, 8, 1),
        Date.new(2026, 9, 1),
        Date.new(2026, 10, 1),
        Date.new(2026, 11, 1),
        Date.new(2026, 12, 1),
        Date.new(2027, 1, 1)
      ])
    end

    it 'limita o número de meses projetados a no máximo 12' do
      base_params = {
        description: "Internet Fibra",
        date: "05/08/2026",
        transaction_type: "expense",
        category_id: category.id,
        supplier_id: supplier.id,
        bank_account_id: bank_account.id
      }

      creator = described_class.new(
        account: account,
        base_params: base_params,
        amount: 99.90,
        months_count: 24 # Tenta passar 24, mas deve limitar a 12
      )

      txs = creator.call
      expect(txs.size).to eq(12)
    end
  end
end
