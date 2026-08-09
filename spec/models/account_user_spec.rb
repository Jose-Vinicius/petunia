require 'rails_helper'

RSpec.describe AccountUser, type: :model do
  describe 'validações e relacionamentos' do
    it 'é válido com atributos válidos' do
      account_user = build(:account_user)
      expect(account_user).to be_valid
    end

    it 'exige papel (role) presente' do
      account_user = build(:account_user, role: nil)
      expect(account_user).not_to be_valid
      expect(account_user.errors[:role]).to include("não pode ficar em branco")
    end

    it 'permite apenas papéis válidos' do
      account_user = build(:account_user, role: "invalid_role")
      expect(account_user).not_to be_valid
      expect(account_user.errors[:role]).to include("não está incluído na lista")
    end

    it 'impede vincular o mesmo usuário mais de uma vez à mesma conta' do
      existente = create(:account_user)
      duplicado = build(:account_user, user: existente.user, account: existente.account)
      expect(duplicado).not_to be_valid
      expect(duplicado.errors[:user_id]).to include("já está em uso")
    end
  end
end
