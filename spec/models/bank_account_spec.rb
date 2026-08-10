require 'rails_helper'

RSpec.describe BankAccount, type: :model do
  describe 'validações e relacionamentos' do
    it 'é válido com atributos válidos' do
      bank_account = build(:bank_account)
      expect(bank_account).to be_valid
    end

    it 'exige um nome presente' do
      bank_account = build(:bank_account, name: nil)
      expect(bank_account).not_to be_valid
      expect(bank_account.errors[:name]).to include("não pode ficar em branco")
    end

    it 'rejeita nomes duplicados dentro do mesmo ambiente' do
      existente = create(:bank_account, name: 'Nubank')
      duplicada = build(:bank_account, account: existente.account, name: 'Nubank')
      expect(duplicada).not_to be_valid
      expect(duplicada.errors[:name]).to include("já está em uso")
    end

    it 'permite o mesmo nome de conta em ambientes diferentes' do
      create(:bank_account, name: 'Nubank')
      outra_conta = build(:bank_account, name: 'Nubank')
      expect(outra_conta).to be_valid
    end

    it 'remove cartões de crédito associados ao excluir a conta bancária' do
      bank_account = create(:bank_account)
      create(:credit_card, bank_account: bank_account, account: bank_account.account)

      expect {
        bank_account.destroy
      }.to change(CreditCard, :count).by(-1)
    end
  end
end
