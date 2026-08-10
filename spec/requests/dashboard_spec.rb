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

    it "exibe o link para o dashboard na página inicial quando autenticado" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dashboard_path)
    end
  end
end
