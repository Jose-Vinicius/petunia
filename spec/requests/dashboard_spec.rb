require 'rails_helper'

RSpec.describe "Dashboard Financeiro", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }
  let(:category) { account.categories.first }
  let(:bank_account) { create(:bank_account, account: account) }

  describe "quando o usuário não está autenticado" do
    it "redireciona para login ao acessar /dashboard" do
      get dashboard_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "quando o usuário está autenticado" do
    before do
      sign_in user
    end

    it "exibe o painel com saldo consolidado e transações recentes" do
      create(:transaction, :income, account: account, category: category, bank_account: bank_account, amount: 2000, description: "Salário")
      create(:transaction, :expense, account: account, category: category, bank_account: bank_account, amount: 500, description: "Aluguel")

      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Painel Financeiro")
      expect(response.body).to include("Salário")
      expect(response.body).to include("Aluguel")
    end

    it "filtra o dashboard por intervalo de datas e categoria" do
      cat_alimentacao = create(:category, account: account, name: "Alimentação Específica")
      cat_lazer = create(:category, account: account, name: "Lazer Específico")

      create(:transaction, :expense, account: account, category: cat_alimentacao, bank_account: bank_account, amount: 120, date: Date.new(2026, 5, 10), description: "Jantar Especial")
      create(:transaction, :expense, account: account, category: cat_lazer, bank_account: bank_account, amount: 200, date: Date.new(2026, 5, 15), description: "Cinema")

      get dashboard_path, params: { start_date: "2026-05-01", end_date: "2026-05-31", category_id: cat_alimentacao.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jantar Especial")
      expect(response.body).not_to include("Cinema")
    end

    it "exibe o link para o dashboard na página inicial quando autenticado" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dashboard_path)
    end
  end
end
