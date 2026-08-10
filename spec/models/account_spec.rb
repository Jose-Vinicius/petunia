require 'rails_helper'

RSpec.describe Account, type: :model do
  describe 'validações e relacionamentos' do
    it 'é válido com atributos válidos' do
      account = build(:account)
      expect(account).to be_valid
    end

    it 'exige um nome presente' do
      account = build(:account, name: nil)
      expect(account).not_to be_valid
      expect(account.errors[:name]).to include("não pode ficar em branco")
    end

    it 'possui associação com usuários através de account_users' do
      user = create(:user)
      account = user.accounts.first
      expect(account.users).to include(user)
    end

    it 'cria automaticamente categorias e centros de custo padrão ao criar uma conta' do
      account = create(:account)
      expect(account.categories.pluck(:name)).to include("Alimentação", "Moradia", "Transporte", "Lazer", "Saúde", "Educação", "Salário")
      expect(account.cost_centers.pluck(:name)).to include("Pessoal", "Trabalho", "Projetos")
      expect(account.categories.where(default: true).count).to eq(7)
      expect(account.cost_centers.where(default: true).count).to eq(3)
    end
  end
end
