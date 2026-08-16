require 'rails_helper'

RSpec.describe "Categorias (Categories)", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }

  describe "quando o usuário não está autenticado" do
    it "redireciona para login ao acessar /categories" do
      get categories_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "quando o usuário está autenticado" do
    before do
      sign_in user
    end

    describe "GET /categories" do
      it "lista as categorias do ambiente ativo" do
        get categories_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Alimentação")
        expect(response.body).to include("Moradia")
      end
    end

    describe "GET /categories/new" do
      it "exibe o formulário de criação de categoria" do
        get new_category_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Nova Categoria")
      end
    end

    describe "POST /categories" do
      context "com parâmetros válidos" do
        it "cria uma categoria personalizada vinculada ao ambiente ativo" do
          expect {
            post categories_path, params: { category: { name: "Assinaturas" } }
          }.to change(account.categories, :count).by(1)

          new_cat = account.categories.find_by(name: "Assinaturas")
          expect(new_cat).to be_present
          expect(new_cat.default).to be false
          expect(response).to redirect_to(categories_path)
          follow_redirect!
          expect(response.body).to include("Assinaturas")
        end
      end

      context "com parâmetros válidos (JSON - cadastro rápido)" do
        it "retorna JSON com id e nome da nova categoria" do
          expect {
            post categories_path, params: { category: { name: "Pets" } }, as: :json
          }.to change(account.categories, :count).by(1)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["id"]).to be_present
          expect(json["name"]).to eq("Pets")
        end
      end

      context "com parâmetros inválidos (JSON)" do
        it "retorna mensagens de erro em JSON" do
          expect {
            post categories_path, params: { category: { name: "" } }, as: :json
          }.not_to change(Category, :count)

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include("Nome da Categoria não pode ficar em branco")
        end
      end
    end

    describe "GET /categories/:id/edit" do
      it "exibe o formulário de edição" do
        cat = create(:category, name: "Mercado", account: account)
        get edit_category_path(cat)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Mercado")
      end

      it "impede editar categoria de outro ambiente" do
        other_account = create(:account)
        other_cat = create(:category, name: "Outro", account: other_account)
        get edit_category_path(other_cat)
        expect(response).to redirect_to(categories_path)
      end
    end

    describe "PATCH /categories/:id" do
      it "atualiza o nome da categoria" do
        cat = create(:category, name: "Supermercado", account: account)
        patch category_path(cat), params: { category: { name: "Mercado & Feira" } }
        expect(response).to redirect_to(categories_path)
        expect(cat.reload.name).to eq("Mercado & Feira")
      end
    end

    describe "DELETE /categories/:id" do
      it "remove a categoria do ambiente" do
        cat = create(:category, name: "Para Excluir", account: account)
        expect {
          delete category_path(cat)
        }.to change(account.categories, :count).by(-1)

        expect(response).to redirect_to(categories_path)
      end
    end
  end
end
