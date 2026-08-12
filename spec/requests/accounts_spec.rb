require 'rails_helper'

RSpec.describe 'Gerenciamento de Contas / Ambientes (Accounts)', type: :request do
  let(:usuario) { create(:user) }

  context 'quando o usuário não está autenticado' do
    it 'redireciona para a página de login ao acessar /accounts' do
      get accounts_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redireciona para a página de login ao tentar criar conta' do
      post accounts_path, params: { account: { name: 'Nova Conta' } }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'quando o usuário está autenticado' do
    before do
      sign_in usuario
    end

    describe 'GET /accounts' do
      it 'retorna sucesso e lista as contas do usuário' do
        conta_extra = create(:account, name: 'Empresa X')
        create(:account_user, user: usuario, account: conta_extra, role: 'owner')

        get accounts_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Conta Pessoal')
        expect(response.body).to include('Empresa X')
      end
    end

    describe 'GET /accounts/new' do
      it 'exibe o formulário de criação de ambiente' do
        get new_account_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Novo Ambiente')
      end
    end

    describe 'POST /accounts' do
      it 'cria uma nova conta e define como ambiente ativo' do
        expect {
          post accounts_path, params: { account: { name: 'Conta Família' } }
        }.to change(Account, :count).by(1)

        nova_conta = Account.find_by(name: 'Conta Família')
        expect(nova_conta).not_to be_nil
        expect(usuario.accounts).to include(nova_conta)

        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(flash[:notice]).to include("Ambiente 'Conta Família' criado com sucesso.")
        expect(session[:current_account_id]).to eq(nova_conta.id)
      end

      it 'rejeita criação com nome em branco' do
        expect {
          post accounts_path, params: { account: { name: '' } }
        }.not_to change(Account, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('não pode ficar em branco')
      end
    end

    describe 'POST /accounts/:id/switch' do
      it 'alterna o ambiente ativo para uma conta pertencente ao usuário' do
        outra_conta = create(:account, name: 'Projeto Startup')
        create(:account_user, user: usuario, account: outra_conta, role: 'owner')

        post switch_account_path(outra_conta)

        expect(session[:current_account_id]).to eq(outra_conta.id)
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(flash[:notice]).to include("Ambiente alterado para 'Projeto Startup'.")
      end

      it 'impede alternar para uma conta que não pertence ao usuário' do
        conta_alheia = create(:account, name: 'Conta Secreta Outro Usuário')

        post switch_account_path(conta_alheia)

        expect(session[:current_account_id]).not_to eq(conta_alheia.id)
        expect(flash[:alert]).to eq('Você não tem permissão para acessar esta conta.')
      end
    end

    describe 'POST /accounts/:id/reset_data' do
      let(:account) { usuario.accounts.first }
      let!(:bank_account) { create(:bank_account, account: account) }
      let!(:credit_card) { create(:credit_card, account: account, bank_account: bank_account) }
      let!(:category) { create(:category, account: account, name: 'Personalizada') }

      before do
        create(:transaction, account: account, bank_account: bank_account, category: category, amount: 150)
      end

      it 'reseta todas as transações, cartões, contas bancárias e recria cadastros padrão quando o usuário é proprietário' do
        expect(account.transactions.count).to eq(1)
        expect(account.bank_accounts.count).to eq(1)
        expect(account.credit_cards.count).to eq(1)

        post reset_data_account_path(account)

        expect(response).to redirect_to(accounts_path)
        follow_redirect!
        expect(flash[:notice]).to include("resetados com sucesso")

        account.reload
        expect(account.transactions.count).to eq(0)
        expect(account.bank_accounts.count).to eq(0)
        expect(account.credit_cards.count).to eq(0)
        expect(account.categories.pluck(:name)).to include('Alimentação', 'Moradia', 'Salário')
        expect(account.categories.pluck(:name)).not_to include('Personalizada')
      end

      it 'impede o reset quando o usuário é apenas membro sem papel de proprietário' do
        outra_conta = create(:account, name: 'Empresa Compartilhada')
        create(:account_user, user: usuario, account: outra_conta, role: 'member')

        post reset_data_account_path(outra_conta)

        expect(flash[:alert]).to eq('Apenas o proprietário da conta tem permissão para resetar os dados.')
      end
    end
  end
end
