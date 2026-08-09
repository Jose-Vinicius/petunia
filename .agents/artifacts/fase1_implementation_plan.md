# 📋 Plano de Implementação — Fase 1: Setup do Projeto e Design System Base

Este documento apresenta o plano detalhado de execução da **Fase 1** da aplicação **Petunia** (Sistema de Controle Financeiro Pessoal em Ruby on Rails).

---

## 🎯 Goal Description

O objetivo da Fase 1 é estruturar os pilares fundamentais da aplicação Petunia:
1. **Infraestrutura de Testes (RSpec + FactoryBot em PT-BR):** Substituir/estender a suíte padrão por RSpec com Factories, suporte a locale `pt-BR` e estrutura para testes expressivos em português.
2. **Autenticação Base (Devise):** Instalar e configurar a gem Devise, configurando enviadores de e-mail e rotas de suporte.
3. **Design System "Obsidian — High-Contrast Dark":** Implementar o design system baseado na especificação (`#09090b`, `#a78bfa`, `#34d399`, superfícies zinc, bordas finas e fonte Geist), reaproveitando os componentes existentes em `.agents/design/components`.
4. **Página Inicial e Estilização de Autenticação:** Criar a controller/view inicial e adequar as páginas do Devise ao tema escuro de alto contraste.

---

## ⚠️ User Review Required

> [!IMPORTANT]
> **Alterações no Gemfile & Instalação de Gems:** Adicionaremos as gems `devise`, `rspec-rails` e `factory_bot_rails`. Rodaremos os comandos `bundle install`, `rails g rspec:install` e `rails g devise:install`.

> [!NOTE]
> **Design System Obsidian:** O layout padrão `application.html.erb` e as views do Devise serão estilizados utilizando os componentes pré-desenhados em `.agents/design/components/` e variáveis CSS customizadas no tema Obsidian Dark.

---

## ❓ Open Questions

> [!NOTE]
> Não há bloqueios pendentes. Caso deseje incluir I18n completo para traduzir todas as mensagens internas do Devise em PT-BR, podemos adicionar a gem `devise-i18n`.
R: Sim, pode adicionar o I18n junto com a lista de palavras em ingles e PT-br e sempre usar ela na criação das telas

---

## 🛠 Proposed Changes

### Componente 1: Dependências (`Gemfile`)

#### [MODIFY] `Gemfile`
Adicionar `devise` no grupo global e `rspec-rails`, `factory_bot_rails` nos grupos `:development, :test`.

```ruby
# Gemfile
gem "devise"

group :development, :test do
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
  # ...
end
```

---

### Componente 2: Configuração de Locale e RSpec (PT-BR)

#### [MODIFY] `config/application.rb`
Configurar a aplicação para utilizar `pt-BR` como timezone e locale padrão.

```ruby
config.time_zone = "Brasilia"
config.i18n.default_locale = :"pt-BR"
```

#### [NEW] `config/locales/pt-BR.yml`
Arquivo básico de traduções em Português do Brasil para mensagens da aplicação.

#### [NEW] `.rspec`
```text
--require spec_helper
--format documentation
```

#### [NEW] `spec/rails_helper.rb` e `spec/spec_helper.rb`
Configurar inclusão de helpers do FactoryBot e suporte a testes do Rails em português.

---

### Componente 3: Autenticação (Devise)

#### [NEW] `config/initializers/devise.rb`
Configurar `config.mailer_sender = 'nao-responda@petunia.local'`.

#### [MODIFY] `config/environments/development.rb`
Configurar host padrão para ActionMailer em ambiente de desenvolvimento:
```ruby
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

#### [NEW] Views do Devise (`app/views/devise/...`)
Geradas via `rails g devise:views` e adaptadas com markup compatível com o tema Obsidian Dark.

---

### Componente 4: Controller Inicial (Landing Page / Home)

#### [NEW] `app/controllers/home_controller.rb`
Controller simples para servir a página inicial e direcionar usuários autenticados.

#### [NEW] `app/views/home/index.html.erb`
Página inicial no estilo Obsidian reutilizando componentes de `.agents/design/components/`.

#### [MODIFY] `config/routes.rb`
Definir rota raiz:
```ruby
root "home#index"
```

---

### Componente 5: Design System "Obsidian Dark" & Layout

#### [NEW] `app/assets/stylesheets/obsidian.css` (ou inclusão em `application.css`)
Variáveis CSS e utilitários da especificação visual conforme `.agents/design/design.md`.

#### [MODIFY] `app/views/layouts/application.html.erb`
Importar a fonte Geist, integrar componentes de header/nav (`.agents/design/components/_header.html.erb`), alertas flash estilizados e contêiner principal.

---

## 🧪 Verification Plan

### Automated Tests
1. Rodar instalação e suite RSpec:
   ```bash
   bundle exec rspec
   ```
2. Criar e executar teste de fumaça da rota raiz (`spec/requests/home_spec.rb`) em PT-BR.

### Manual Verification
1. Inicializar o servidor Rails (`rails server`).
2. Acessar `http://localhost:3000` e validar o tema escuro Obsidian.
3. Acessar rotas do Devise (`/users/sign_in`, `/users/sign_up`) e testar formulários.
