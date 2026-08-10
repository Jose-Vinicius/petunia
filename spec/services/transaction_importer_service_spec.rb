require 'rails_helper'
require 'tempfile'

RSpec.describe TransactionImporterService, type: :service do
  let(:account) { create(:account) }
  let(:bank_account) { create(:bank_account, account: account) }
  let(:credit_card) { create(:credit_card, account: account, bank_account: bank_account) }

  describe '#call' do
    context 'com um arquivo CSV válido contendo receitas e despesas' do
      let(:csv_content) do
        <<~CSV
          data,descrição,valor,tipo,categoria,centro_de_custo
          10/08/2026,Salário Mensal,3500.00,receita,Salário,Trabalho
          11/08/2026,Supermercado Exemplo,-250.50,despesa,Alimentação,Pessoal
        CSV
      end

      let(:temp_file) do
        file = Tempfile.new([ 'transactions', '.csv' ])
        file.write(csv_content)
        file.rewind
        file
      end

      after do
        temp_file.close
        temp_file.unlink
      end

      it 'importa com sucesso as transações e cria categorias se necessário' do
        service = described_class.new(
          file_path: temp_file.path,
          filename: 'transactions.csv',
          account: account,
          bank_account_id: bank_account.id
        )

        result = service.call

        expect(result.success_count).to eq(2)
        expect(result.error_count).to eq(0)
        expect(account.transactions.count).to eq(2)

        income_tx = account.transactions.find_by(description: 'Salário Mensal')
        expect(income_tx).to be_present
        expect(income_tx.amount).to eq(3500.00)
        expect(income_tx.transaction_type).to eq('income')
        expect(income_tx.bank_account).to eq(bank_account)

        expense_tx = account.transactions.find_by(description: 'Supermercado Exemplo')
        expect(expense_tx).to be_present
        expect(expense_tx.amount).to eq(250.50)
        expect(expense_tx.transaction_type).to eq('expense')
      end

      it 'trata formato de moeda brasileira com vírgula e R$' do
        br_csv = <<~CSV
          data,descrição,valor,tipo,categoria
          12/08/2026,Aluguel,"R$ 1.200,50",despesa,Moradia
        CSV

        file = Tempfile.new([ 'br_tx', '.csv' ])
        file.write(br_csv)
        file.rewind

        service = described_class.new(
          file_path: file.path,
          filename: 'br_tx.csv',
          account: account,
          bank_account_id: bank_account.id
        )

        result = service.call
        expect(result.success_count).to eq(1)

        tx = account.transactions.find_by(description: 'Aluguel')
        expect(tx.amount).to eq(1200.50)

        file.close
        file.unlink
      end
    end
  end
end
