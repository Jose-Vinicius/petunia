require 'rails_helper'

RSpec.describe Transaction, type: :model do
  describe 'validações e regras de negócio' do
    let(:account) { create(:account) }
    let(:category) { account.categories.first }
    let(:bank_account) { create(:bank_account, account: account) }
    let(:credit_card) { create(:credit_card, account: account, bank_account: bank_account) }

    it 'é válido com atributos válidos (receita em conta bancária)' do
      tx = build(:transaction, :income, account: account, category: category, bank_account: bank_account)
      expect(tx).to be_valid
    end

    it 'é válido com despesa em cartão de crédito' do
      tx = build(:transaction, :expense, account: account, category: category, bank_account: nil, credit_card: credit_card)
      expect(tx).to be_valid
    end

    it 'exige descrição, data, valor e tipo presentes' do
      tx = build(:transaction, description: nil, date: nil, amount: nil, transaction_type: nil)
      expect(tx).not_to be_valid
      expect(tx.errors[:description]).to include("não pode ficar em branco")
      expect(tx.errors[:date]).to include("não pode ficar em branco")
      expect(tx.errors[:amount]).to include("não pode ficar em branco")
      expect(tx.errors[:transaction_type]).to include("não pode ficar em branco")
    end

    it 'rejeita valores menores ou iguais a zero' do
      tx = build(:transaction, account: account, category: category, bank_account: bank_account, amount: 0)
      expect(tx).not_to be_valid
      expect(tx.errors[:amount]).to include("deve ser maior que 0")
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

    it 'impede associar categoria de outro ambiente' do
      other_account = create(:account)
      other_cat = other_account.categories.first
      tx = build(:transaction, account: account, category: other_cat, bank_account: bank_account)
      expect(tx).not_to be_valid
      expect(tx.errors[:category]).to include("inválida para esta conta")
    end

    it 'impede associar conta bancária de outro ambiente' do
      other_account = create(:account)
      other_bank = create(:bank_account, account: other_account)
      tx = build(:transaction, account: account, category: category, bank_account: other_bank)
      expect(tx).not_to be_valid
      expect(tx.errors[:bank_account]).to include("inválida para esta conta")
    end
  end
end
