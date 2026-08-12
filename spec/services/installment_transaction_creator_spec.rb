require "rails_helper"

RSpec.describe InstallmentTransactionCreator do
  let(:account) { create(:account) }
  let(:category) { create(:category, account: account) }
  let(:supplier) { create(:supplier, account: account) }
  let(:bank_account) { create(:bank_account, account: account) }
  let(:credit_card) { create(:credit_card, account: account, bank_account: bank_account, closing_day: 5, due_day: 15) }

  describe "#call" do
    context "com lançamento parcelado em cartão de crédito" do
      it "cria N parcelas dividindo o valor total e incrementando o mês da competência" do
        base_params = {
          transaction_type: "expense",
          description: "Smartphone",
          amount: 1000.0,
          date: Date.new(2026, 8, 10),
          category_id: category.id,
          supplier_id: supplier.id,
          credit_card_id: credit_card.id
        }

        creator = described_class.new(
          account: account,
          base_params: base_params,
          installments_count: 10,
          total_amount: 1000.0
        )

        txs = creator.call
        expect(txs.size).to eq(10)
        expect(txs.map(&:amount).sum).to eq(1000.0)

        # Descriptions
        expect(txs.first.description).to eq("Smartphone (1/10)")
        expect(txs.last.description).to eq("Smartphone (10/10)")

        # Group ID
        expect(txs.map(&:installment_group_id).uniq.size).to eq(1)

        # Competence progression across 10 months
        # For purchase on Aug 10 with closing_day=5, initial competence is Sept 15 (2026-09-15)
        expect(txs[0].competence_date).to eq(Date.new(2026, 9, 15))
        expect(txs[1].competence_date).to eq(Date.new(2026, 10, 15))
        expect(txs[9].competence_date).to eq(Date.new(2027, 6, 15))
      end

      it "trata divisão com resto de centavos na primeira parcela" do
        base_params = {
          transaction_type: "expense",
          description: "Tenis",
          amount: 100.0,
          date: Date.new(2026, 8, 1),
          category_id: category.id,
          supplier_id: supplier.id,
          credit_card_id: credit_card.id
        }

        creator = described_class.new(
          account: account,
          base_params: base_params,
          installments_count: 3,
          total_amount: 100.0
        )

        txs = creator.call
        expect(txs.size).to eq(3)
        expect(txs[0].amount).to eq(33.34)
        expect(txs[1].amount).to eq(33.33)
        expect(txs[2].amount).to eq(33.33)
        expect(txs.map(&:amount).sum).to eq(100.0)
      end
    end

    context "com lançamento parcelado em conta bancária" do
      it "incrementa tanto a data do lançamento quanto a competência a cada mês" do
        base_params = {
          transaction_type: "expense",
          description: "Curso Anual",
          amount: 600.0,
          date: Date.new(2026, 8, 10),
          competence_date: Date.new(2026, 8, 10),
          category_id: category.id,
          supplier_id: supplier.id,
          bank_account_id: bank_account.id
        }

        creator = described_class.new(
          account: account,
          base_params: base_params,
          installments_count: 6,
          total_amount: 600.0
        )

        txs = creator.call
        expect(txs.size).to eq(6)
        expect(txs.map(&:amount)).to all(eq(100.0))

        expect(txs[0].date).to eq(Date.new(2026, 8, 10))
        expect(txs[1].date).to eq(Date.new(2026, 9, 10))
        expect(txs[5].date).to eq(Date.new(2027, 1, 10))
      end
    end
  end
end
