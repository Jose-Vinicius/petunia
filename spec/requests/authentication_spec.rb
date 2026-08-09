require 'rails_helper'

RSpec.describe 'Autenticação (Devise)', type: :request do
  describe 'GET /users/sign_in' do
    it 'carrega a tela de login' do
      get new_user_session_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Entrar na sua conta')
    end
  end

  describe 'GET /users/sign_up' do
    it 'carrega a tela de cadastro' do
      get new_user_registration_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Criar nova conta')
    end
  end

  describe 'POST /users (Cadastro)' do
    it 'cadastra um novo usuário com dados válidos' do
      expect {
        post user_registration_path, params: {
          user: {
            email: 'novo_usuario@petunia.local',
            password: 'senha123password',
            password_confirmation: 'senha123password'
          }
        }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:notice]).to eq('Bem-vindo! Você se cadastrou com sucesso.')
    end

    it 'impede cadastro com e-mail duplicado' do
      create(:user, email: 'existente@petunia.local')

      expect {
        post user_registration_path, params: {
          user: {
            email: 'existente@petunia.local',
            password: 'senha123password',
            password_confirmation: 'senha123password'
          }
        }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('já está em uso')
    end

    it 'impede cadastro com e-mail duplicado usando letras maiúsculas' do
      create(:user, email: 'existente@petunia.local')

      expect {
        post user_registration_path, params: {
          user: {
            email: 'EXISTENTE@PETUNIA.LOCAL',
            password: 'senha123password',
            password_confirmation: 'senha123password'
          }
        }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('já está em uso')
    end

    it 'impede cadastro com senha curta' do
      expect {
        post user_registration_path, params: {
          user: {
            email: 'curto@petunia.local',
            password: '123',
            password_confirmation: '123'
          }
        }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('é muito curto (mínimo: 6 caracteres)')
    end

    it 'impede cadastro quando a confirmação de senha não confere' do
      expect {
        post user_registration_path, params: {
          user: {
            email: 'diferente@petunia.local',
            password: 'senha123password',
            password_confirmation: 'outrasenha123'
          }
        }
      }.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('não é igual a Senha')
    end
  end

  describe 'POST /users/sign_in (Login)' do
    it 'autentica o usuário com credenciais válidas' do
      create(:user, email: 'teste@petunia.local', password: 'senha123password', password_confirmation: 'senha123password')

      post user_session_path, params: {
        user: {
          email: 'teste@petunia.local',
          password: 'senha123password'
        }
      }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('teste@petunia.local')
      expect(flash[:notice]).to eq('Login efetuado com sucesso.')
    end

    it 'exibe mensagem de erro em português para e-mail inexistente' do
      post user_session_path, params: {
        user: {
          email: 'inexistente@petunia.local',
          password: 'senha123password'
        }
      }

      expect(response.body).to include('E-mail ou senha inválidos.')
    end

    it 'exibe mensagem de erro em português para senha incorreta' do
      create(:user, email: 'teste@petunia.local', password: 'senha123password', password_confirmation: 'senha123password')

      post user_session_path, params: {
        user: {
          email: 'teste@petunia.local',
          password: 'senha_incorreta'
        }
      }

      expect(response.body).to include('E-mail ou senha inválidos.')
    end
  end

  describe 'DELETE /users/sign_out (Logout)' do
    it 'desconecta o usuário autenticado' do
      usuario = create(:user)
      sign_in usuario

      delete destroy_user_session_path

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(flash[:notice]).to eq('Logout efetuado com sucesso.')
    end
  end
end
