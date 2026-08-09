require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validações e factory' do
    it 'cria um usuário válido com a factory padrão' do
      usuario = build(:user)
      expect(usuario).to be_valid
    end

    context 'validações de e-mail' do
      it 'exige um e-mail presente' do
        usuario = build(:user, email: nil)
        expect(usuario).not_to be_valid
        expect(usuario.errors[:email]).to include("não pode ficar em branco")
      end

      it 'rejeita formatos de e-mail inválidos' do
        emails_invalidos = [ 'invalido', 'usuario@', '@dominio.com', 'com espaco@dominio.com', 'duplo@@dominio.com' ]
        emails_invalidos.each do |email_invalido|
          usuario = build(:user, email: email_invalido)
          expect(usuario).not_to be_valid
          expect(usuario.errors[:email]).to include("não é válido")
        end
      end

      it 'não permite e-mails duplicados' do
        create(:user, email: 'teste@petunia.local')
        duplicado = build(:user, email: 'teste@petunia.local')
        expect(duplicado).not_to be_valid
        expect(duplicado.errors[:email]).to include("já está em uso")
      end

      it 'não permite e-mails duplicados ignorando maiúsculas e minúsculas' do
        create(:user, email: 'teste@petunia.local')
        duplicado = build(:user, email: 'TESTE@PETUNIA.LOCAL')
        expect(duplicado).not_to be_valid
        expect(duplicado.errors[:email]).to include("já está em uso")
      end
    end

    context 'validações de senha' do
      it 'exige uma senha presente no cadastro' do
        usuario = build(:user, password: nil)
        expect(usuario).not_to be_valid
        expect(usuario.errors[:password]).to include("não pode ficar em branco")
      end

      it 'rejeita senhas com menos de 6 caracteres' do
        usuario = build(:user, password: '12345', password_confirmation: '12345')
        expect(usuario).not_to be_valid
        expect(usuario.errors[:password]).to include("é muito curto (mínimo: 6 caracteres)")
      end

      it 'aceita senhas com 6 ou mais caracteres' do
        usuario = build(:user, password: '123456', password_confirmation: '123456')
        expect(usuario).to be_valid
      end

      it 'exige que a confirmação de senha corresponda à senha' do
        usuario = build(:user, password: 'senha123password', password_confirmation: 'outrasenha123')
        expect(usuario).not_to be_valid
        expect(usuario.errors[:password_confirmation]).to include("não é igual a Senha")
      end
    end
  end
end
