require 'rails_helper'

RSpec.describe "Importação por Planilha (Imports)", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }
  let(:bank_account) { create(:bank_account, account: account) }

  describe "quando o usuário não está autenticado" do
    it "redireciona para login ao acessar /imports/new" do
      get new_import_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "quando o usuário está autenticado" do
    before do
      sign_in user
    end

    describe "GET /imports/new" do
      it "exibe o formulário de upload de planilha" do
        get new_import_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Importar Transações por Planilha")
      end
    end

    describe "POST /imports/preview" do
      it "retorna JSON com as linhas do preview e coleções" do
        file = fixture_file_upload(
          Rails.root.join('spec/fixtures/files/sample_transactions.csv'),
          'text/csv'
        )

        post preview_imports_path, params: { file: file, bank_account_id: bank_account.id }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["rows"]).to be_an(Array)
        expect(json["collections"]).to be_present
      end

      it "rejeita requisição sem arquivo no preview" do
        post preview_imports_path, params: {}

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Por favor, selecione um arquivo de planilha válido para enviar.")
      end
    end

    describe "POST /imports (confirmação em lote via preview)" do
      it "cria transações no banco a partir do payload confirmado" do
        category = account.categories.first
        supplier = create(:supplier, account: account)

        payload = [
          {
            date: Date.current.to_s,
            description: "Supermercado Confirmado",
            amount: 150.00,
            transaction_type: "expense",
            category: { id: category.id },
            supplier: { id: supplier.id },
            bank_account: { id: bank_account.id }
          }
        ]

        expect {
          post imports_path, params: { transactions: payload }, as: :json
        }.to change(account.transactions, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["count"]).to eq(1)

        tx = account.transactions.find_by(description: "Supermercado Confirmado")
        expect(tx).to be_present
        expect(tx.amount).to eq(150.00)
      end

      it "cria automaticamente nova conta bancária e cartão de crédito se forem especificados como novos" do
        payload = [
          {
            date: "08/08/2026",
            description: "Festval Catuaicascavelbra",
            amount: 15.17,
            transaction_type: "expense",
            category: { id: nil, name: "alimento" },
            supplier: { id: nil, name: "Festval Catuai" },
            cost_center: { id: nil, name: "beatriz" },
            bank_account: { id: nil, name: "Itau" },
            credit_card: { id: nil, name: "Azul" }
          }
        ]

        expect {
          post imports_path, params: { transactions: payload }, as: :json
        }.to change(account.transactions, :count).by(1)
         .and change(account.bank_accounts, :count).by(1)
         .and change(account.credit_cards, :count).by(1)

        expect(response).to have_http_status(:ok)
        tx = account.transactions.find_by(description: "Festval Catuaicascavelbra")
        expect(tx).to be_present
        expect(tx.credit_card.name).to eq("Azul")
        expect(tx.credit_card.bank_account.name).to eq("Itau")
      end

      it "cria múltiplas parcelas quando installments_count > 1 no payload" do
        category = account.categories.first
        supplier = create(:supplier, account: account)

        payload = [
          {
            date: Date.current.to_s,
            description: "Notebook Gamer",
            amount: 3000.00,
            transaction_type: "expense",
            installments_count: 3,
            category: { id: category.id },
            supplier: { id: supplier.id },
            bank_account: { id: bank_account.id }
          }
        ]

        expect {
          post imports_path, params: { transactions: payload }, as: :json
        }.to change(account.transactions, :count).by(3)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["count"]).to eq(3)

        txs = account.transactions.where("description LIKE ?", "Notebook Gamer%")
        expect(txs.count).to eq(3)
        expect(txs.pluck(:amount)).to eq([1000.0, 1000.0, 1000.0])
      end
    end

    describe "POST /imports (envio direto via form tradicional)" do
      it "processa envio de planilha CSV com sucesso" do
        file = fixture_file_upload(
          Rails.root.join('spec/fixtures/files/sample_transactions.csv'),
          'text/csv'
        )

        post imports_path, params: { file: file, bank_account_id: bank_account.id }

        expect(response).to redirect_to(transactions_path)
        follow_redirect!
        expect(response.body).to include("transações importadas com sucesso")
      end
    end

    describe "GET /imports/download_template" do
      it "faz o download do modelo apenas com cabeçalho" do
        get download_template_imports_path(sample: false)

        expect(response).to have_http_status(:ok)
        expect(response.header['Content-Type']).to include('text/csv')
        expect(response.body).to include("Data;Data Competência;Descrição;Valor;Tipo;Categoria;Fornecedor;Centro de Custo;Conta Bancária;Cartão de Crédito;Parcela Atual;Parcela Total;Estorno")
      end

      it "faz o download do modelo com dados de exemplo" do
        get download_template_imports_path(sample: true)

        expect(response).to have_http_status(:ok)
        expect(response.header['Content-Type']).to include('text/csv')
        expect(response.body).to include("Salário Mensal")
        expect(response.body).to include("Supermercado")
      end
    end
  end
end
