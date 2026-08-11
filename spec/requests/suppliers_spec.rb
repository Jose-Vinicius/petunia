require 'rails_helper'

RSpec.describe "Fornecedores (Suppliers)", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }

  describe "quando o usuário não está autenticado" do
    it "redireciona para login ao acessar /suppliers" do
      get suppliers_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "quando o usuário está autenticado" do
    before do
      sign_in user
    end

    describe "GET /suppliers" do
      it "lista os fornecedores do ambiente ativo" do
        create(:supplier, name: "Supermercado Central", account: account)
        get suppliers_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Supermercado Central")
      end
    end

    describe "GET /suppliers/new" do
      it "exibe o formulário de criação de fornecedor" do
        get new_supplier_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Novo Fornecedor / Cliente")
      end
    end

    describe "POST /suppliers" do
      context "com parâmetros válidos (HTML)" do
        it "cria um fornecedor vinculado ao ambiente ativo" do
          expect {
            post suppliers_path, params: { supplier: { name: "Empresa ACME" } }
          }.to change(account.suppliers, :count).by(1)

          new_sup = account.suppliers.find_by(name: "Empresa ACME")
          expect(new_sup).to be_present
          expect(response).to redirect_to(suppliers_path)
          follow_redirect!
          expect(response.body).to include("Empresa ACME")
        end
      end

      context "com parâmetros válidos (JSON - cadastro rápido)" do
        it "retorna JSON com id e nome do novo fornecedor" do
          expect {
            post suppliers_path, params: { supplier: { name: "Posto Shell" } }, as: :json
          }.to change(account.suppliers, :count).by(1)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["id"]).to be_present
          expect(json["name"]).to eq("Posto Shell")
        end
      end

      context "com parâmetros inválidos (JSON)" do
        it "retorna mensagens de erro em JSON" do
          expect {
            post suppliers_path, params: { supplier: { name: "" } }, as: :json
          }.not_to change(Supplier, :count)

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include("Nome do Fornecedor / Cliente não pode ficar em branco")
        end
      end
    end

    describe "GET /suppliers/:id/edit" do
      it "exibe o formulário de edição" do
        sup = create(:supplier, name: "Mercado Local", account: account)
        get edit_supplier_path(sup)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Mercado Local")
      end

      it "impede editar fornecedor de outro ambiente" do
        other_account = create(:account)
        other_sup = create(:supplier, name: "Outro", account: other_account)
        get edit_supplier_path(other_sup)
        expect(response).to redirect_to(suppliers_path)
      end
    end

    describe "PATCH /suppliers/:id" do
      it "atualiza o nome do fornecedor" do
        sup = create(:supplier, name: "Mercado Antigo", account: account)
        patch supplier_path(sup), params: { supplier: { name: "Mercado Novo" } }
        expect(response).to redirect_to(suppliers_path)
        expect(sup.reload.name).to eq("Mercado Novo")
      end
    end

    describe "DELETE /suppliers/:id" do
      it "remove o fornecedor do ambiente" do
        sup = create(:supplier, name: "Para Excluir", account: account)
        expect {
          delete supplier_path(sup)
        }.to change(account.suppliers, :count).by(-1)

        expect(response).to redirect_to(suppliers_path)
      end
    end
  end
end
