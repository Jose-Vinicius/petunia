require 'rails_helper'

RSpec.describe RecurringTransaction, type: :model do
  let(:account) { create(:account) }
  let(:category) { account.categories.first }
  let(:supplier) { create(:supplier, account: account) }

  it 'é válido com atributos válidos' do
    rec = described_class.new(
      account: account,
      description: "Aluguel da Casa",
      amount: 900.00,
      transaction_type: "expense",
      frequency: "monthly",
      start_date: Date.current,
      category: category,
      supplier: supplier
    )

    expect(rec).to be_valid
  end

  it 'exige descrição, valor, tipo, frequência e data de início' do
    rec = described_class.new(frequency: nil)
    expect(rec).not_to be_valid
    expect(rec.errors[:description]).to include("não pode ficar em branco")
    expect(rec.errors[:amount]).to include("não pode ficar em branco")
    expect(rec.errors[:transaction_type]).to include("não pode ficar em branco")
    expect(rec.errors[:frequency]).to include("não pode ficar em branco")
    expect(rec.errors[:start_date]).to include("não pode ficar em branco")
  end

  it 'rejeita valor menor ou igual a zero' do
    rec = described_class.new(amount: 0)
    rec.valid?
    expect(rec.errors[:amount]).to include("deve ser maior que 0")
  end

  it 'alterna o status ativo/pausado via toggle_active!' do
    rec = described_class.create!(
      account: account,
      description: "Aluguel",
      amount: 900.00,
      transaction_type: "expense",
      frequency: "monthly",
      start_date: Date.current,
      category: category,
      supplier: supplier,
      active: true
    )

    rec.toggle_active!
    expect(rec.active).to be false

    rec.toggle_active!
    expect(rec.active).to be true
  end
end
