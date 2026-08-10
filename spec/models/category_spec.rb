require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'validações e relacionamentos' do
    let(:account) { create(:account) }

    it 'é válido com atributos válidos' do
      category = build(:category, account: account)
      expect(category).to be_valid
    end

    it 'exige um nome presente' do
      category = build(:category, name: nil, account: account)
      expect(category).not_to be_valid
      expect(category.errors[:name]).to include("não pode ficar em branco")
    end

    it 'rejeita nomes duplicados dentro do mesmo ambiente' do
      create(:category, name: 'Restaurantes', account: account)
      duplicate = build(:category, name: 'restaurantes', account: account)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("já está em uso")
    end

    it 'permite o mesmo nome de categoria em ambientes diferentes' do
      other_account = create(:account)
      create(:category, name: 'Restaurantes', account: account)
      other_category = build(:category, name: 'Restaurantes', account: other_account)
      expect(other_category).to be_valid
    end
  end
end
