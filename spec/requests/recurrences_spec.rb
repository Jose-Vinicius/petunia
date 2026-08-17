require 'rails_helper'

RSpec.describe "Lançamentos Recorrentes (Recurrences)", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }
  let(:category) { account.categories.first }
  let(:supplier) { create(:supplier, account: account) }
  let(:bank_account) { create(:bank_account, account: account) }

  describe "quando o usuário não está autenticado" do
    it "redireciona para o login ao acessar /recurrences" do
      get recurrences_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "quando o usuário está autenticado" do
    before { sign_in user }

    describe "GET /recurrences" do
      it "lista as regras de recorrência da conta ativa" do
        account.recurring_transactions.create!(
          description: "Aluguel",
          amount: 1200.00,
          transaction_type: "expense",
          frequency: "monthly",
          start_date: Date.current,
          category: category,
          supplier: supplier
        )

        get recurrences_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Aluguel")
        expect(response.body).to include("1.200,00")
      end
    end

    describe "POST /recurrences" do
      it "cria uma nova recorrência e projeta transações" do
        payload = {
          recurring_transaction: {
            description: "Condomínio",
            amount: "450,00",
            transaction_type: "expense",
            frequency: "monthly",
            start_date: "10/08/2026",
            category_id: category.id,
            supplier_id: supplier.id,
            bank_account_id: bank_account.id
          },
          recurring_months_count: 5
        }

        expect {
          post recurrences_path, params: payload
        }.to change(account.recurring_transactions, :count).by(1)
         .and change(account.transactions, :count).by(5)

        expect(response).to redirect_to(recurrences_path)
      end
    end

    describe "PATCH /recurrences/:id/toggle_active" do
      it "alterna o status ativo/pausado da recorrência" do
        rec = account.recurring_transactions.create!(
          description: "Netflix",
          amount: 55.90,
          transaction_type: "expense",
          frequency: "monthly",
          start_date: Date.current,
          category: category,
          active: true
        )

        patch toggle_active_recurrence_path(rec)
        expect(response).to redirect_to(recurrences_path)
        expect(rec.reload.active).to be false
      end
    end

    describe "DELETE /recurrences/:id" do
      it "remove a recorrência e os lançamentos pendentes futuros" do
        creator = RecurringTransactionCreator.new(
          account: account,
          base_params: {
            description: "Spotify",
            date: (Date.current + 1.month).strftime("%d/%m/%Y"),
            transaction_type: "expense",
            category_id: category.id,
            bank_account_id: bank_account.id
          },
          amount: 21.90,
          months_count: 3
        )
        txs = creator.call
        rec = account.recurring_transactions.first

        expect {
          delete recurrence_path(rec)
        }.to change(account.recurring_transactions, :count).by(-1)
         .and change(account.transactions.pending, :count).by(-3)

        expect(response).to redirect_to(recurrences_path)
      end
    end
  end
end
