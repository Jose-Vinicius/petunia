require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'validações e regras de negócio' do
    let(:account) { create(:account) }
    let(:category) { account.categories.first }
    let(:supplier) { create(:supplier, account: account) }
    let(:bank_account) { create(:bank_account, account: account) }
    let(:credit_card) { create(:credit_card, account: account, bank_account: bank_account) }

    it 'é válido com atributos válidos (receita em conta bancária)' do
      tx = build(:transaction, :income, account: account, category: category, supplier: supplier, bank_account: bank_account)
      expect(tx).to be_valid
    end

    it 'é válido com despesa em cartão de crédito' do
      tx = build(:transaction, :expense, account: account, category: category, supplier: supplier, bank_account: nil, credit_card: credit_card)
      expect(tx).to be_valid
    end

    it 'exige descrição, data, valor, tipo e fornecedor presentes' do
      tx = build(:transaction, description: nil, date: nil, amount: nil, transaction_type: nil, supplier: nil)
      expect(tx).not_to be_valid
      expect(tx.errors[:description]).to include("não pode ficar em branco")
      expect(tx.errors[:date]).to include("não pode ficar em branco")
      expect(tx.errors[:amount]).to include("não pode ficar em branco")
      expect(tx.errors[:transaction_type]).to include("não pode ficar em branco")
      expect(tx.errors[:supplier_id]).to include("não pode ficar em branco")
    end

    it 'rejeita valores menores ou iguais a zero' do
      tx = build(:transaction, account: account, category: category, bank_account: bank_account, amount: 0)
      expect(tx).not_to be_valid
      expect(tx.errors[:amount]).to include("deve ser maior que 0")
    end

    it 'aceita valor numérico informado como string com vírgula (ex: "15,17" ou "1.200,50")' do
      tx1 = build(:transaction, :income, account: account, category: category, supplier: supplier, bank_account: bank_account, amount: "15,17")
      expect(tx1.amount).to eq(15.17)

      tx2 = build(:transaction, :income, account: account, category: category, supplier: supplier, bank_account: bank_account, amount: "1.200,50")
      expect(tx2.amount).to eq(1200.50)
    end

    it 'rejeita receitas sem conta bancária' do
      tx = build(:transaction, :income, account: account, category: category, bank_account: nil)
      expect(tx).not_to be_valid
      expect(tx.errors[:bank_account_id]).to include("é obrigatória para lançamentos de receita")
    end

    it 'rejeita receitas com cartão de crédito' do
      tx = build(:transaction, :income, account: account, category: category, bank_account: bank_account, credit_card: credit_card)
      expect(tx).not_to be_valid
      expect(tx.errors[:credit_card_id]).to include("não pode ser utilizado para lançamentos de receita")
    end

    it 'rejeita despesas sem meio de pagamento (sem conta bancária nem cartão)' do
      tx = build(:transaction, :expense, account: account, category: category, bank_account: nil, credit_card: nil)
      expect(tx).not_to be_valid
      expect(tx.errors[:base]).to include("Informe uma Conta Bancária ou um Cartão de Crédito como forma de pagamento")
    end

    it 'permite estorno apenas para lançamentos em cartão de crédito' do
      tx_bank = build(:transaction, :expense, account: account, category: category, supplier: supplier, bank_account: bank_account, credit_card: nil, is_refund: true)
      expect(tx_bank).not_to be_valid
      expect(tx_bank.errors[:is_refund]).to include("só pode ser aplicado em lançamentos de cartão de crédito")

      tx_card = build(:transaction, :expense, account: account, category: category, supplier: supplier, credit_card: credit_card, bank_account: nil, is_refund: true)
      expect(tx_card).to be_valid
    end

    it 'impede associar categoria de outro ambiente' do
      other_account = create(:account)
      other_cat = other_account.categories.first
      tx = build(:transaction, account: account, category: other_cat, bank_account: bank_account)
      expect(tx).not_to be_valid
      expect(tx.errors[:category]).to include("inválida para esta conta")
    end

    it 'impede associar fornecedor de outro ambiente' do
      other_account = create(:account)
      other_sup = create(:supplier, account: other_account)
      tx = build(:transaction, account: account, category: category, supplier: other_sup, bank_account: bank_account)
      expect(tx).not_to be_valid
      expect(tx.errors[:supplier]).to include("inválido para esta conta")
    end

    it 'impede associar conta bancária de outro ambiente' do
      other_account = create(:account)
      other_bank = create(:bank_account, account: other_account)
      tx = build(:transaction, account: account, category: category, bank_account: other_bank)
      expect(tx).not_to be_valid
      expect(tx.errors[:bank_account]).to include("inválida para esta conta")
    end

    describe 'atribuição de data de competência (competence_date)' do
      let(:card_fechamento_25) { create(:credit_card, account: account, bank_account: bank_account, closing_day: 25, due_day: 5) }

      it 'calcula automaticamente a data da fatura para lançamento em cartão' do
        tx = create(:transaction, :expense, account: account, category: category, supplier: supplier, credit_card: card_fechamento_25, bank_account: nil, date: Date.new(2026, 8, 20), competence_date: nil)
        expect(tx.competence_date).to eq(Date.new(2026, 9, 5))
      end

      it 'atribui a mesma data da compra para lançamentos em conta bancária quando não informada' do
        tx = create(:transaction, :income, account: account, category: category, supplier: supplier, bank_account: bank_account, date: Date.new(2026, 8, 10), competence_date: nil)
        expect(tx.competence_date).to eq(Date.new(2026, 8, 10))
      end

      it 'preserva a data de competência caso fornecida manualmente' do
        tx = create(:transaction, :expense, account: account, category: category, supplier: supplier, credit_card: card_fechamento_25, bank_account: nil, date: Date.new(2026, 8, 20), competence_date: Date.new(2026, 11, 5))
        expect(tx.competence_date).to eq(Date.new(2026, 11, 5))
      end
    end

    describe 'regras de status da transação (pending vs realized)' do
      it 'atribui status realized por padrão para lançamentos com data de hoje ou passada' do
        tx = create(:transaction, :income, account: account, category: category, supplier: supplier, bank_account: bank_account, date: Date.current)
        expect(tx.status).to eq("realized")
        expect(tx).to be_realized
      end

      it 'atribui status pending por padrão para lançamentos com data no futuro' do
        tx = create(:transaction, :income, account: account, category: category, supplier: supplier, bank_account: bank_account, date: Date.current + 5.days, status: nil)
        expect(tx.status).to eq("pending")
        expect(tx).to be_pending
      end

      it 'permite criar lançamento futuro como realized caso especificado' do
        tx = create(:transaction, :income, account: account, category: category, supplier: supplier, bank_account: bank_account, date: Date.current + 5.days, status: "realized")
        expect(tx.status).to eq("realized")
      end

      it 'filtra corretamente via scopes realized e pending' do
        realized_tx = create(:transaction, :income, account: account, category: category, supplier: supplier, bank_account: bank_account, date: Date.current, status: "realized")
        pending_tx = create(:transaction, :income, account: account, category: category, supplier: supplier, bank_account: bank_account, date: Date.current + 2.days, status: "pending")

        expect(account.transactions.realized).to include(realized_tx)
        expect(account.transactions.realized).not_to include(pending_tx)

        expect(account.transactions.pending).to include(pending_tx)
        expect(account.transactions.pending).not_to include(realized_tx)
      end
    end
  end
end
