require 'rails_helper'

RSpec.describe CreditCard, type: :model do
  describe 'validações e relacionamentos' do
    it 'é válido com atributos válidos' do
      credit_card = build(:credit_card)
      expect(credit_card).to be_valid
    end

    it 'exige um nome presente' do
      credit_card = build(:credit_card, name: nil)
      expect(credit_card).not_to be_valid
      expect(credit_card.errors[:name]).to include("não pode ficar em branco")
    end

    it 'exige um limite não negativo' do
      credit_card = build(:credit_card, limit: -50)
      expect(credit_card).not_to be_valid
      expect(credit_card.errors[:limit]).to include("deve ser maior ou igual a 0")
    end

    it 'rejeita nomes duplicados no mesmo ambiente' do
      existente = create(:credit_card, name: 'Ultravioleta')
      duplicado = build(:credit_card, account: existente.account, bank_account: existente.bank_account, name: 'Ultravioleta')
      expect(duplicado).not_to be_valid
      expect(duplicado.errors[:name]).to include("já está em uso")
    end

    it 'impede vincular o cartão a uma conta bancária de outro ambiente' do
      outro_ambiente = create(:account)
      conta_bancaria_outra = create(:bank_account, account: outro_ambiente)
      meu_ambiente = create(:account)

      cartao = build(:credit_card, account: meu_ambiente, bank_account: conta_bancaria_outra)
      expect(cartao).not_to be_valid
      expect(cartao.errors[:bank_account]).to include("não é válido")
    end
  end

  describe '#invoice_competence_for' do
    let(:card) { create(:credit_card, closing_day: 25, due_day: 5) }

    it 'atribui fatura do mês seguinte quando a compra é feita até o dia de fechamento' do
      competence = card.invoice_competence_for(Date.new(2026, 8, 20))
      expect(competence).to eq(Date.new(2026, 9, 5))
    end

    it 'atribui fatura do mês subsequente quando a compra é feita após o dia de fechamento' do
      competence = card.invoice_competence_for(Date.new(2026, 8, 26))
      expect(competence).to eq(Date.new(2026, 10, 5))
    end
  end

  describe '#spent_unpaid' do
    let(:card) { create(:credit_card, closing_day: 25, due_day: 5) }
    let(:account) { card.account }
    let(:category) { account.categories.first }
    let(:supplier) { create(:supplier, account: account) }

    it 'abate estornos do saldo gasto não pago' do
      create(:transaction, :expense, account: account, category: category, supplier: supplier, credit_card: card, bank_account: nil, amount: 264.06, competence_date: Date.new(2026, 9, 5), is_refund: false)
      create(:transaction, :expense, account: account, category: category, supplier: supplier, credit_card: card, bank_account: nil, amount: 43.59, competence_date: Date.new(2026, 9, 5), is_refund: true)
      create(:transaction, :expense, account: account, category: category, supplier: supplier, credit_card: card, bank_account: nil, amount: 86.81, competence_date: Date.new(2026, 9, 5), is_refund: true)
      create(:transaction, :expense, account: account, category: category, supplier: supplier, credit_card: card, bank_account: nil, amount: 43.59, competence_date: Date.new(2026, 9, 5), is_refund: true)

      expect(card.spent_unpaid).to eq(90.07)
    end
  end
end
