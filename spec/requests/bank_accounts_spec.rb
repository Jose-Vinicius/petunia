require 'rails_helper'

RSpec.describe 'Contas Bancárias (BankAccounts)', type: :request do
  let(:usuario) { create(:user) }
  let(:conta) { usuario.accounts.first }

  context 'quando o usuário não está autenticado' do
    it 'redireciona para login ao acessar /bank_accounts' do
      get bank_accounts_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'quando o usuário está autenticado' do
    before do
      sign_in usuario
    end

    describe 'GET /bank_accounts' do
      it 'lista as contas bancárias do ambiente ativo' do
        banco1 = create(:bank_account, account: conta, name: 'Nubank')

        outro_ambiente = create(:account)
        create(:bank_account, account: outro_ambiente, name: 'Banco Secreto Outro Ambiente')

        get bank_accounts_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Nubank')
        expect(response.body).not_to include('Banco Secreto Outro Ambiente')
      end
    end

    describe 'GET /bank_accounts/new' do
      it 'exibe o formulário de criação de conta bancária' do
        get new_bank_account_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Nova Conta Bancária')
      end
    end

    describe 'POST /bank_accounts' do
      it 'cria uma conta bancária vinculada ao ambiente ativo' do
        expect {
          post bank_accounts_path, params: { bank_account: { name: 'Itaú Unibanco' } }
        }.to change(BankAccount, :count).by(1)

        expect(response).to redirect_to(bank_accounts_path)
        follow_redirect!
        expect(flash[:notice]).to include("Conta bancária 'Itaú Unibanco' criada com sucesso.")

        banco = BankAccount.find_by(name: 'Itaú Unibanco')
        expect(banco.account).to eq(conta)
      end

      it 'rejeita a criação com nome em branco' do
        expect {
          post bank_accounts_path, params: { bank_account: { name: '' } }
        }.not_to change(BankAccount, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('não pode ficar em branco')
      end
    end

    describe 'GET /bank_accounts/:id/edit' do
      it 'exibe formulário de edição' do
        banco = create(:bank_account, account: conta, name: 'Bradesco')
        get edit_bank_account_path(banco)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Editar Conta Bancária')
        expect(response.body).to include('Bradesco')
      end

      it 'impede editar conta bancária de outro ambiente' do
        outro_ambiente = create(:account)
        banco_alheio = create(:bank_account, account: outro_ambiente)

        get edit_bank_account_path(banco_alheio)
        expect(response).to redirect_to(bank_accounts_path)
        expect(flash[:alert]).to eq('Conta bancária não encontrada.')
      end
    end

    describe 'PATCH /bank_accounts/:id' do
      it 'atualiza o nome da conta bancária' do
        banco = create(:bank_account, account: conta, name: 'Santander Antigo')

        patch bank_account_path(banco), params: { bank_account: { name: 'Santander Select' } }

        expect(response).to redirect_to(bank_accounts_path)
        follow_redirect!
        expect(flash[:notice]).to include("Conta bancária 'Santander Select' atualizada com sucesso.")
        expect(banco.reload.name).to eq('Santander Select')
      end
    end

    describe 'DELETE /bank_accounts/:id' do
      it 'remove a conta bancária do ambiente' do
        banco = create(:bank_account, account: conta)

        expect {
          delete bank_account_path(banco)
        }.to change(BankAccount, :count).by(-1)

        expect(response).to redirect_to(bank_accounts_path)
        follow_redirect!
        expect(flash[:notice]).to include('removida com sucesso')
      end
    end
  end
end
