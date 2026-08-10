require 'rails_helper'

RSpec.describe CostCenter, type: :model do
  describe 'validações e relacionamentos' do
    let(:account) { create(:account) }

    it 'é válido com atributos válidos' do
      cost_center = build(:cost_center, account: account)
      expect(cost_center).to be_valid
    end

    it 'exige um nome presente' do
      cost_center = build(:cost_center, name: nil, account: account)
      expect(cost_center).not_to be_valid
      expect(cost_center.errors[:name]).to include("não pode ficar em branco")
    end

    it 'rejeita nomes duplicados dentro do mesmo ambiente' do
      create(:cost_center, name: 'Viagens', account: account)
      duplicate = build(:cost_center, name: 'viagens', account: account)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("já está em uso")
    end

    it 'permite o mesmo nome de centro de custo em ambientes diferentes' do
      other_account = create(:account)
      create(:cost_center, name: 'Viagens', account: account)
      other_cost_center = build(:cost_center, name: 'Viagens', account: other_account)
      expect(other_cost_center).to be_valid
    end
  end
end
