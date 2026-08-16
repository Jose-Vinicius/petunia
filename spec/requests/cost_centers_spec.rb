require 'rails_helper'

RSpec.describe "Centros de Custo (CostCenters)", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }

  describe "quando o usuário não está autenticado" do
    it "redireciona para login ao acessar /cost_centers" do
      get cost_centers_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "quando o usuário está autenticado" do
    before do
      sign_in user
    end

    describe "GET /cost_centers" do
      it "lista os centros de custo do ambiente ativo" do
        get cost_centers_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Pessoal")
        expect(response.body).to include("Trabalho")
      end
    end

    describe "GET /cost_centers/new" do
      it "exibe o formulário de criação de centro de custo" do
        get new_cost_center_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Novo Centro de Custo")
      end
    end

    describe "POST /cost_centers" do
      context "com parâmetros válidos" do
        it "cria um centro de custo personalizado vinculado ao ambiente ativo" do
          expect {
            post cost_centers_path, params: { cost_center: { name: "Viagens" } }
          }.to change(account.cost_centers, :count).by(1)

          new_cc = account.cost_centers.find_by(name: "Viagens")
          expect(new_cc).to be_present
          expect(new_cc.default).to be false
          expect(response).to redirect_to(cost_centers_path)
          follow_redirect!
          expect(response.body).to include("Viagens")
        end
      end

      context "com parâmetros válidos (JSON - cadastro rápido)" do
        it "retorna JSON com id e nome do novo centro de custo" do
          expect {
            post cost_centers_path, params: { cost_center: { name: "Projetos 2026" } }, as: :json
          }.to change(account.cost_centers, :count).by(1)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["id"]).to be_present
          expect(json["name"]).to eq("Projetos 2026")
        end
      end

      context "com parâmetros inválidos (JSON)" do
        it "retorna mensagens de erro em JSON" do
          expect {
            post cost_centers_path, params: { cost_center: { name: "" } }, as: :json
          }.not_to change(CostCenter, :count)

          expect(response).to have_http_status(:unprocessable_content)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include("Nome do Centro de Custo não pode ficar em branco")
        end
      end
    end

    describe "GET /cost_centers/:id/edit" do
      it "exibe o formulário de edição" do
        cc = create(:cost_center, name: "Reforma", account: account)
        get edit_cost_center_path(cc)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Reforma")
      end

      it "impede editar centro de custo de outro ambiente" do
        other_account = create(:account)
        other_cc = create(:cost_center, name: "Outro CC", account: other_account)
        get edit_cost_center_path(other_cc)
        expect(response).to redirect_to(cost_centers_path)
      end
    end

    describe "PATCH /cost_centers/:id" do
      it "atualiza o nome do centro de custo" do
        cc = create(:cost_center, name: "Viagem SP", account: account)
        patch cost_center_path(cc), params: { cost_center: { name: "Viagem SP 2026" } }
        expect(response).to redirect_to(cost_centers_path)
        expect(cc.reload.name).to eq("Viagem SP 2026")
      end
    end

    describe "DELETE /cost_centers/:id" do
      it "remove o centro de custo do ambiente" do
        cc = create(:cost_center, name: "Para Excluir CC", account: account)
        expect {
          delete cost_center_path(cc)
        }.to change(account.cost_centers, :count).by(-1)

        expect(response).to redirect_to(cost_centers_path)
      end
    end
  end
end
