require 'rails_helper'
require 'tempfile'

RSpec.describe TransactionImporterService, type: :service do
  let(:account) { create(:account) }
  let!(:bank_account) { create(:bank_account, name: "Nubank", account: account) }
  let!(:credit_card) { create(:credit_card, name: "Visa Itaú", account: account, bank_account: bank_account) }

  describe '#parse_preview' do
    let(:csv_content) do
      <<~CSV
        data,descrição,valor,tipo,categoria,fornecedor,centro_de_custo,banco,cartao
        10/08/2026,Salário Mensal,3500.00,receita,Salário,Empresa ACME,Trabalho,Nubank,
        11/08/2026,Supermercado Exemplo,-250.50,despesa,Alimentação,Mercado Centraall,Pessoal,,Visa Itaú
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

    it 'retorna estrutura de preview identificando entidades existentes vs novas' do
      service = described_class.new(
        file_path: temp_file.path,
        filename: 'transactions.csv',
        account: account
      )

      preview = service.parse_preview
      expect(preview[:errors]).to be_empty
      expect(preview[:rows].size).to eq(2)

      row1 = preview[:rows].first
      expect(row1[:description]).to eq('Salário Mensal')
      expect(row1[:amount]).to eq(3500.00)
      expect(row1[:transaction_type]).to eq('income')
      expect(row1[:bank_account][:id]).to eq(bank_account.id)
      expect(row1[:bank_account][:is_new]).to be false

      row2 = preview[:rows].second
      expect(row2[:supplier][:name]).to eq('Mercado Centraall')
      expect(row2[:supplier][:is_new]).to be true
      expect(row2[:credit_card][:id]).to eq(credit_card.id)
      expect(row2[:credit_card][:is_new]).to be false
    end
  end

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

  describe '.parse_date' do
    it 'interpreta corretamente datas no formato DD/MM/AAAA' do
      expect(described_class.parse_date('05/04/2026')).to eq(Date.new(2026, 4, 5))
      expect(described_class.parse_date('31/12/2025')).to eq(Date.new(2025, 12, 31))
    end

    it 'interpreta corretamente datas no formato DD-MM-AAAA' do
      expect(described_class.parse_date('05-04-2026')).to eq(Date.new(2026, 4, 5))
    end

    it 'interpreta corretamente datas no formato DD.MM.AAAA' do
      expect(described_class.parse_date('05.04.2026')).to eq(Date.new(2026, 4, 5))
    end

    it 'interpreta corretamente datas no formato DD/MM/YY (ano com 2 dígitos)' do
      expect(described_class.parse_date('05/04/26')).to eq(Date.new(2026, 4, 5))
    end

    it 'interpreta corretamente datas acompanhadas de horário DD/MM/AAAA HH:MM:SS' do
      expect(described_class.parse_date('05/04/2026 14:30:00')).to eq(Date.new(2026, 4, 5))
      expect(described_class.parse_date('05-04-2026 00:00')).to eq(Date.new(2026, 4, 5))
    end

    it 'interpreta corretamente formato ISO YYYY-MM-DD' do
      expect(described_class.parse_date('2026-04-05')).to eq(Date.new(2026, 4, 5))
    end

    it 'preserva objetos de data Date e DateTime' do
      date_obj = Date.new(2026, 4, 5)
      datetime_obj = DateTime.new(2026, 4, 5, 10, 0, 0)
      expect(described_class.parse_date(date_obj)).to eq(date_obj)
      expect(described_class.parse_date(datetime_obj)).to eq(date_obj)
    end

    it 'interpreta corretamente datas no formato MM/AAAA ou MM/YY (mês/ano de competência)' do
      expect(described_class.parse_date('08/2026')).to eq(Date.new(2026, 8, 1))
      expect(described_class.parse_date('08/26')).to eq(Date.new(2026, 8, 1))
    end

    it 'retorna nil para valores nulos ou inválidos' do
      expect(described_class.parse_date(nil)).to be_nil
      expect(described_class.parse_date('')).to be_nil
      expect(described_class.parse_date('texto_invalido')).to be_nil
    end
  end
end
