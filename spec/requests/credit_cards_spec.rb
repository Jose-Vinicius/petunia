require 'rails_helper'

RSpec.describe 'Cartões de Crédito (CreditCards)', type: :request do
  let(:usuario) { create(:user) }
  let(:conta) { usuario.accounts.first }
  let!(:banco) { create(:bank_account, account: conta, name: 'Nubank') }

  context 'quando o usuário não está autenticado' do
    it 'redireciona para login ao acessar /credit_cards' do
      get credit_cards_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context 'quando o usuário está autenticado' do
    before do
      sign_in usuario
    end

    describe 'GET /credit_cards' do
      it 'lista os cartões de crédito do ambiente ativo' do
        cartao1 = create(:credit_card, account: conta, bank_account: banco, name: 'Ultravioleta', limit: 8000.00)

        outro_ambiente = create(:account)
        banco_outro = create(:bank_account, account: outro_ambiente)
        create(:credit_card, account: outro_ambiente, bank_account: banco_outro, name: 'Cartão Secreto Outro Ambiente')

        get credit_cards_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Ultravioleta')
        expect(response.body).not_to include('Cartão Secreto Outro Ambiente')
      end
    end

    describe 'GET /credit_cards/new' do
      it 'exibe o formulário de criação de cartão de crédito' do
        get new_credit_card_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Novo Cartão de Crédito')
      end
    end

    describe 'POST /credit_cards' do
      it 'cria um cartão de crédito vinculado ao ambiente ativo e à conta bancária' do
        expect {
          post credit_cards_path, params: {
            credit_card: {
              name: 'XP Visa Infinite',
              limit: 15000.50,
              bank_account_id: banco.id
            }
          }
        }.to change(CreditCard, :count).by(1)

        expect(response).to redirect_to(credit_cards_path)
        follow_redirect!
        expect(flash[:notice]).to include("Cartão de crédito 'XP Visa Infinite' criado com sucesso.")

        cartao = CreditCard.find_by(name: 'XP Visa Infinite')
        expect(cartao.account).to eq(conta)
        expect(cartao.bank_account).to eq(banco)
        expect(cartao.limit).to eq(15000.50)
      end

      it 'rejeita a criação com limite negativo' do
        expect {
          post credit_cards_path, params: {
            credit_card: {
              name: 'Inválido',
              limit: -100,
              bank_account_id: banco.id
            }
          }
        }.not_to change(CreditCard, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('deve ser maior ou igual a 0')
      end

      it 'impede associar cartão a uma conta bancária de outro ambiente' do
        outro_ambiente = create(:account)
        banco_alheio = create(:bank_account, account: outro_ambiente)

        expect {
          post credit_cards_path, params: {
            credit_card: {
              name: 'Hacker Card',
              limit: 1000.00,
              bank_account_id: banco_alheio.id
            }
          }
        }.not_to change(CreditCard, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('não é válido')
      end
    end

    describe 'GET /credit_cards/:id/edit' do
      it 'exibe formulário de edição' do
        cartao = create(:credit_card, account: conta, bank_account: banco, name: 'C6 Black')
        get edit_credit_card_path(cartao)

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Editar Cartão de Crédito')
        expect(response.body).to include('C6 Black')
      end
    end

    describe 'PATCH /credit_cards/:id' do
      it 'atualiza limite e nome do cartão de crédito' do
        cartao = create(:credit_card, account: conta, bank_account: banco, name: 'Inter Platinum', limit: 3000.00)

        patch credit_card_path(cartao), params: {
          credit_card: {
            name: 'Inter Black',
            limit: 10000.00,
            bank_account_id: banco.id
          }
        }

        expect(response).to redirect_to(credit_cards_path)
        follow_redirect!
        expect(flash[:notice]).to include("Cartão de crédito 'Inter Black' atualizado com sucesso.")
        expect(cartao.reload.name).to eq('Inter Black')
        expect(cartao.limit).to eq(10000.00)
      end
    end

    describe 'DELETE /credit_cards/:id' do
      it 'remove o cartão de crédito' do
        cartao = create(:credit_card, account: conta, bank_account: banco)

        expect {
          delete credit_card_path(cartao)
        }.to change(CreditCard, :count).by(-1)

        expect(response).to redirect_to(credit_cards_path)
        follow_redirect!
        expect(flash[:notice]).to include('removido com sucesso')
      end
    end
  end
end
