# 🚀 Walkthrough — Fase 1: Setup do Projeto & Design System Base

A **Fase 1** da aplicação **Petunia** foi concluída com sucesso. Todos os testes automatizados foram executados e aprovados.

---

## 💡 Resumo das Alterações Realizadas

### 1. Infraestrutura de Testes e I18n (PT-BR)
- **Gems Adicionadas:** `rspec-rails`, `factory_bot_rails`, `devise` e `devise-i18n`.
- **Configuração de Locale:** `config.i18n.default_locale = :"pt-BR"` e `config.time_zone = "Brasilia"` em [application.rb](file:///var/home/josevinicius/data/projects/personal/petunia/config/application.rb).
- **RSpec Helper:** `spec/rails_helper.rb` configurado com `FactoryBot::Syntax::Methods` e helpers do Devise.
- **Dicionário em Português:** Criado [pt-BR.yml](file:///var/home/josevinicius/data/projects/personal/petunia/config/locales/pt-BR.yml).

### 2. Autenticação Base (Devise)
- **Model `User`:** Gerado com migration e factory pronta ([user.rb](file:///var/home/josevinicius/data/projects/personal/petunia/app/models/user.rb) e [users.rb](file:///var/home/josevinicius/data/projects/personal/petunia/spec/factories/users.rb)).
- **ActionMailer:** Configurado `default_url_options` em [development.rb](file:///var/home/josevinicius/data/projects/personal/petunia/config/environments/development.rb).
- **Views do Devise:** Telas de login ([sessions/new.html.erb](file:///var/home/josevinicius/data/projects/personal/petunia/app/views/devise/sessions/new.html.erb)) e cadastro ([registrations/new.html.erb](file:///var/home/josevinicius/data/projects/personal/petunia/app/views/devise/registrations/new.html.erb)) estilizadas de acordo com o tema Obsidian Dark.

### 3. Design System "Obsidian High-Contrast Dark"
- **Estilos Globais:** [application.css](file:///var/home/josevinicius/data/projects/personal/petunia/app/assets/stylesheets/application.css) criado com o tema visual (`#09090b`, `#a78bfa`, `#34d399`, superfícies zinc `#18181b` e bordas `#27272a`).
- **Tipografia:** Importação da fonte **Geist** do Google Fonts.
- **Componente Header:** Reutilizável em [shared/_header.html.erb](file:///var/home/josevinicius/data/projects/personal/petunia/app/views/shared/_header.html.erb) com status dinâmico do usuário logado.
- **Landing Page & Layout:** Criado [home_controller.rb](file:///var/home/josevinicius/data/projects/personal/petunia/app/controllers/home_controller.rb), view [home/index.html.erb](file:///var/home/josevinicius/data/projects/personal/petunia/app/views/home/index.html.erb) e atualizado o layout [application.html.erb](file:///var/home/josevinicius/data/projects/personal/petunia/app/views/layouts/application.html.erb).

---

## 🧪 Resultados dos Testes Automatizados (RSpec)

Foram criadas suítes de testes em Português para validar o model de usuário, a controller inicial e os fluxos de autenticação do Devise:

```bash
User
  validações e factory
    cria um usuário válido com a factory padrão
    exige um e-mail válido
    não permite e-mails duplicados

Autenticação (Devise)
  GET /users/sign_in
    carrega a tela de login com o tema Obsidian Dark
  GET /users/sign_up
    carrega a tela de cadastro
  POST /users/sign_in
    autentica o usuário com credenciais válidas

Página Inicial (Home)
  GET /
    retorna código HTTP 200 e exibe as informações da aplicação Petunia
    quando o usuário não está autenticado
      exibe os botões de entrar e cadastrar
    quando o usuário está autenticado
      exibe o botão de sair e o e-mail do usuário

Finished in 0.30175 seconds (files took 1.29 seconds to load)
9 examples, 0 failures
```

---

## 🔍 Como Verificar Manualmente

1. Suba o servidor de desenvolvimento:
   ```bash
   bin/rails server
   ```
2. Acesse `http://localhost:3000` no seu navegador para visualizar a landing page no tema **Obsidian High-Contrast Dark**.
3. Clique em **Cadastrar** (`/users/sign_up`) ou **Entrar** (`/users/sign_in`) para visualizar e testar as telas de formulário com o tema escuro.
