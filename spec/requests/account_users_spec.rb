require 'rails_helper'

RSpec.describe 'Gestão de Membros da Conta (AccountUsers)', type: :request do
  let(:dono) { create(:user, email: 'jose@teste.com') }
  let(:conta) { dono.accounts.first }

  context 'quando o usuário não está autenticado' do
    it 'redireciona para a página de login' do
      get account_account_users_path(conta)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'quando o usuário não é proprietário (role: member)' do
    let(:membro) { create(:user, email: 'membro@teste.com') }

    before do
      create(:account_user, user: membro, account: conta, role: 'member')
      sign_in membro
    end

    it 'impede acesso à gestão de membros' do
      get account_account_users_path(conta)
      expect(response).to redirect_to(accounts_path)
      expect(flash[:alert]).to eq('Apenas proprietários da conta podem gerenciar membros.')
    end
  end

  context 'quando o usuário é proprietário (role: owner)' do
    before do
      sign_in dono
    end

    describe 'GET /accounts/:account_id/members' do
      it 'exibe a lista de membros da conta' do
        get account_account_users_path(conta)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Membros do Ambiente')
        expect(response.body).to include('jose@teste.com')
      end
    end

    describe 'POST /accounts/:account_id/members' do
      context 'adicionando um usuário já existente no sistema' do
        let!(:vitoria) { create(:user, email: 'vitoria@teste.com') }

        it 'vincula o usuário à conta existente' do
          expect {
            post account_account_users_path(conta), params: {
              email: 'vitoria@teste.com',
              role: 'member'
            }
          }.to change(AccountUser, :count).by(1)

          expect(response).to redirect_to(account_account_users_path(conta))
          follow_redirect!
          expect(flash[:notice]).to include("Usuário 'vitoria@teste.com' adicionado com sucesso")

          expect(vitoria.accounts).to include(conta)
        end

        it 'permite que a vitoria faça login e acesse a conta compartilhada' do
          post account_account_users_path(conta), params: {
            email: 'vitoria@teste.com',
            role: 'member'
          }

          sign_out dono
          sign_in vitoria

          post switch_account_path(conta)
          expect(response).to redirect_to(root_path)
          follow_redirect!
          expect(flash[:notice]).to include("Ambiente alterado para '#{conta.name}'.")
        end

        it 'rejeita adicionar o mesmo usuário novamente' do
          create(:account_user, user: vitoria, account: conta, role: 'member')

          expect {
            post account_account_users_path(conta), params: {
              email: 'vitoria@teste.com',
              role: 'member'
            }
          }.not_to change(AccountUser, :count)

          expect(response).to redirect_to(account_account_users_path(conta))
          follow_redirect!
          expect(flash[:alert]).to include("O usuário 'vitoria@teste.com' já é membro deste ambiente.")
        end
      end

      context 'adicionando um usuário que ainda não existe no sistema (Opção B)' do
        it 'exige que a senha inicial seja informada com no mínimo 6 caracteres' do
          expect {
            post account_account_users_path(conta), params: {
              email: 'novo_membro@teste.com',
              password: '',
              role: 'member'
            }
          }.not_to change(User, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include('Senha de no mínimo 6 caracteres é obrigatória')
        end

        it 'cria o novo usuário com a senha informada e o vincula à conta' do
          expect {
            expect {
              post account_account_users_path(conta), params: {
                email: 'novo_membro@teste.com',
                password: 'senha_segura123',
                role: 'member'
              }
            }.to change(User, :count).by(1)
          }.to change(AccountUser, :count).by(2) # 1 automatic default account user + 1 shared account user

          novo_usuario = User.find_by(email: 'novo_membro@teste.com')
          expect(novo_usuario).not_to be_nil
          expect(novo_usuario.valid_password?('senha_segura123')).to be true
          expect(novo_usuario.accounts).to include(conta)
        end
      end

      it 'rejeita submissão com e-mail em branco' do
        post account_account_users_path(conta), params: { email: '', role: 'member' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Informe o e-mail do usuário.')
      end
    end

    describe 'DELETE /accounts/:account_id/members/:id' do
      let!(:membro_secundario) { create(:user, email: 'secundario@teste.com') }
      let!(:vinculo) { create(:account_user, user: membro_secundario, account: conta, role: 'member') }

      it 'remove um membro secundário da conta' do
        expect {
          delete account_account_user_path(conta, vinculo)
        }.to change(AccountUser, :count).by(-1)

        expect(response).to redirect_to(account_account_users_path(conta))
        follow_redirect!
        expect(flash[:notice]).to eq('Membro removido da conta com sucesso.')
      end

      it 'impede a remoção do único proprietário da conta' do
        dono_vinculo = conta.account_users.find_by(user: dono)

        expect {
          delete account_account_user_path(conta, dono_vinculo)
        }.not_to change(AccountUser, :count)

        expect(response).to redirect_to(account_account_users_path(conta))
        follow_redirect!
        expect(flash[:alert]).to eq('Não é possível remover o único proprietário da conta.')
      end
    end
  end
end
