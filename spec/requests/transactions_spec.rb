require 'rails_helper'

RSpec.describe "Transações (Transactions)", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }
  let(:category) { account.categories.first }
  let(:cost_center) { account.cost_centers.first }
  let(:bank_account) { create(:bank_account, account: account) }
  let(:credit_card) { create(:credit_card, account: account, bank_account: bank_account) }

  describe "quando o usuário não está autenticado" do
    it "redireciona para login ao acessar /transactions" do
      get transactions_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "quando o usuário está autenticado" do
    before do
      sign_in user
    end

    describe "GET /transactions" do
      it "lista as transações do ambiente ativo" do
        create(:transaction, account: account, category: category, bank_account: bank_account, description: "Salário Empresa")
        get transactions_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Salário Empresa")
      end

      it "filtra transações por tipo (income / expense)" do
        income_tx = create(:transaction, :income, account: account, category: category, bank_account: bank_account, description: "Receita Freelance")
        expense_tx = create(:transaction, :expense, account: account, category: category, bank_account: bank_account, description: "Supermercado")

        get transactions_path, params: { transaction_type: "income", month: "all" }
        expect(response.body).to include("Receita Freelance")
        expect(response.body).not_to include("Supermercado")
      end
    end

    describe "GET /transactions/new" do
      it "exibe o formulário de lançamento" do
        get new_transaction_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Novo Lançamento")
      end
    end

    describe "POST /transactions" do
      context "com parâmetros válidos" do
        it "cria uma transação de receita vinculada à conta bancária" do
          expect {
            post transactions_path, params: {
              transaction: {
                transaction_type: "income",
                description: "Venda de produto",
                amount: 350.00,
                date: Date.current.to_s,
                category_id: category.id,
                cost_center_id: cost_center.id,
                bank_account_id: bank_account.id
              }
            }
          }.to change(account.transactions, :count).by(1)

          expect(response).to redirect_to(transactions_path)
          follow_redirect!
          expect(response.body).to include("Venda de produto")
        end

        it "cria uma transação de despesa vinculada ao cartão de crédito" do
          expect {
            post transactions_path, params: {
              transaction: {
                transaction_type: "expense",
                description: "Restaurante",
                amount: 85.90,
                date: Date.current.to_s,
                category_id: category.id,
                credit_card_id: credit_card.id
              }
            }
          }.to change(account.transactions, :count).by(1)

          expect(response).to redirect_to(transactions_path)
          follow_redirect!
          expect(response.body).to include("Restaurante")
        end
      end

      context "com parâmetros inválidos" do
        it "rejeita valor negativo ou zero" do
          expect {
            post transactions_path, params: {
              transaction: {
                transaction_type: "expense",
                description: "Inválido",
                amount: -10,
                date: Date.current.to_s,
                category_id: category.id,
                bank_account_id: bank_account.id
              }
            }
          }.not_to change(Transaction, :count)

          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    describe "GET /transactions/:id/edit" do
      it "exibe formulário de edição" do
        tx = create(:transaction, account: account, category: category, bank_account: bank_account, description: "Compra Exemplo")
        get edit_transaction_path(tx)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Compra Exemplo")
      end

      it "impede editar transação de outro ambiente" do
        other_account = create(:account)
        other_cat = other_account.categories.first
        other_bank = create(:bank_account, account: other_account)
        other_tx = create(:transaction, account: other_account, category: other_cat, bank_account: other_bank)

        get edit_transaction_path(other_tx)
        expect(response).to redirect_to(transactions_path)
      end
    end

    describe "PATCH /transactions/:id" do
      it "atualiza o valor e descrição da transação" do
        tx = create(:transaction, account: account, category: category, bank_account: bank_account, description: "Antiga", amount: 100)
        patch transaction_path(tx), params: {
          transaction: {
            description: "Nova Descrição",
            amount: 150
          }
        }
        expect(response).to redirect_to(transactions_path)
        expect(tx.reload.description).to eq("Nova Descrição")
        expect(tx.amount).to eq(150)
      end
    end

    describe "DELETE /transactions/:id" do
      it "remove a transação do ambiente" do
        tx = create(:transaction, account: account, category: category, bank_account: bank_account)
        expect {
          delete transaction_path(tx)
        }.to change(account.transactions, :count).by(-1)

        expect(response).to redirect_to(transactions_path)
      end
    end
  end
end
