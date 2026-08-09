require 'rails_helper'

RSpec.describe 'Página Inicial (Home)', type: :request do
  describe 'GET /' do
    it 'retorna código HTTP 200 e exibe as informações da aplicação Petunia' do
      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Petunia')
      expect(response.body).to include('Gerencie seus gastos e receitas')
    end

    context 'quando o usuário não está autenticado' do
      it 'exibe os botões de entrar e cadastrar' do
        get root_path

        expect(response.body).to include('Entrar')
        expect(response.body).to include('Cadastrar')
      end
    end

    context 'quando o usuário está autenticado' do
      it 'exibe o botão de sair e o e-mail do usuário' do
        usuario = create(:user, email: 'joao@petunia.local')
        sign_in usuario

        get root_path

        expect(response.body).to include('joao@petunia.local')
        expect(response.body).to include('Sair')
      end
    end
  end
end
