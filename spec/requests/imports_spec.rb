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

    describe "POST /imports" do
      it "rejeita requisição sem arquivo" do
        post imports_path
        expect(response).to redirect_to(transactions_path)
        follow_redirect!
        expect(response.body).to include("Por favor, selecione um arquivo de planilha válido")
      end

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
        expect(response.body).to include("Data;Descrição;Valor;Tipo;Categoria;Fornecedor;Centro de Custo")
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
