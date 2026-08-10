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
end
