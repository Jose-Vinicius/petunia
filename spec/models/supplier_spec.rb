require 'rails_helper'

RSpec.describe Supplier, type: :model do
  describe 'validações e relacionamentos' do
    let(:account) { create(:account) }

    it 'é válido com atributos válidos' do
      supplier = build(:supplier, account: account)
      expect(supplier).to be_valid
    end

    it 'exige um nome presente' do
      supplier = build(:supplier, name: nil, account: account)
      expect(supplier).not_to be_valid
      expect(supplier.errors[:name]).to include("não pode ficar em branco")
    end

    it 'rejeita nomes duplicados dentro do mesmo ambiente' do
      create(:supplier, name: 'Mercado Central', account: account)
      duplicate = build(:supplier, name: 'mercado central', account: account)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("já está em uso")
    end

    it 'permite o mesmo nome em ambientes diferentes' do
      other_account = create(:account)
      create(:supplier, name: 'Mercado Central', account: account)
      other_supplier = build(:supplier, name: 'Mercado Central', account: other_account)
      expect(other_supplier).to be_valid
    end

    it 'não permite exclusão se houver transações associadas' do
      supplier = create(:supplier, account: account)
      create(:transaction, account: account, supplier: supplier)
      expect(supplier.destroy).to be false
      expect(supplier.errors[:base]).not_to be_empty
    end
  end
end
