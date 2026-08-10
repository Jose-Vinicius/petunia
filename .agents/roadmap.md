# 🗺️ Petunia — Análise de Requisitos & Roadmap Inicial

Este documento contém a análise detalhada dos requisitos e o detalhamento de todas as tarefas iniciais planejadas para o desenvolvimento da aplicação **Petunia** (Sistema de Controle Financeiro Pessoal em Ruby on Rails).

---

## 🎯 Resumo da Análise de Requisitos

### 1. Visão Geral & Arquitetura
* **Backend:** Ruby on Rails 8.1 (Ruby 3.x)
* **Banco de Dados:** PostgreSQL 17
* **Frontend:** Hotwire (Turbo + Stimulus) com visual moderno em Vanilla CSS
* **Design System:** *Obsidian — High-Contrast Dark* (superfície `#09090b`, primário violeta `#a78bfa`, acentos em verde esmeralda `#34d399`, bordas zinc `#27272a` e fonte Geist)
* **Autenticação & Multi-tenancy:** Devise com suporte a múltiplos ambientes (`Accounts`/Tenants). O usuário pode gerenciar/acessar múltiplas contas com o mesmo login (ex: Conta Pessoal, Conta da Família) e selecionar o ambiente ativo no login.
* **Testes:** RSpec configurado para especificações em português (PT-BR).

### 2. Entidades Principais e Relacionamentos
* **`User`**: Usuário do sistema (autenticado via Devise).
* **`Account`**: O ambiente/workspace de controle financeiro. Possui relação N:N com `User` através de `AccountUser`.
* **`BankAccount`**: Conta bancária vinculada a uma `Account`.
* **`CreditCard`**: Cartão de crédito vinculado a uma `BankAccount` e escopado à `Account`. Possui limite total.
* **`Category`**: Categorias de transações (mercado, casa, lazer, etc.). Pode ser padrão do sistema ou personalizada por `Account`.
* **`CostCenter`**: Centros de custo. Pode ser padrão do sistema ou personalizado por `Account`.
* **`Transaction`**: Transação financeira (`income` / `expense`), vinculada a `Category`, `CostCenter`, `BankAccount` (e opcionalmente `CreditCard`).

---

## 📋 Lista de Tarefas Iniciais (Tasks Roadmap)

---

### 🟢 FASE 1: Setup do Projeto e Design System Base
> **Objetivo:** Estabelecer a infraestrutura de testes, autenticação base e o sistema de design visual *Obsidian Dark*.

- [x] **Task 1.1: Configuração do RSpec e FactoryBot (PT-BR)**
  - Adicionar gems `rspec-rails` e `factory_bot_rails` ao `Gemfile`.
  - Rodar `rails generate rspec:install` e configurar suporte a matchers e descrições em Português.
- [x] **Task 1.2: Configuração da Gem Devise**
  - Adicionar `gem "devise"` ao `Gemfile` e executar o setup inicial (`rails generate devise:install`).
  - Configurar views iniciais do Devise.
- [x] **Task 1.3: Implementação do Design System "Obsidian Dark"**
  - Criar variáveis CSS de cores, superfícies zinc, bordas e tipografia Geist em `app/assets/stylesheets/application.css`.
  - Definir estilos globais para botões (primary, secondary, ghost), inputs, cards e layout responsivo.

---

### 🟢 FASE 2: Autenticação, Multi-Tenancy & Seleção de Ambiente
> **Objetivo:** Permitir que o usuário se autentique e navegue entre seus diferentes ambientes (`Accounts`).

- [ ] **Task 2.1: Modelagem e Migrations de `User`, `Account` e `AccountUser`**
  - Gerar model `User` via Devise.
  - Criar model `Account` (nome, created_at, updated_at).
  - Criar tabela pivô `AccountUser` (user_id, account_id, role).
  - Criar testes RSpec para associações e validações dos models.
- [ ] **Task 2.2: Contexto de Ambiente Ativo e Seletor de Account**
  - Implementar lógica de `current_account` no `ApplicationController` mantido na sessão.
  - Criar tela/modal de seleção de ambiente no pós-login caso o usuário possua mais de 1 conta.
  - Criar seletor rápido no menu da aplicação para alternar entre contas.
  - Testes RSpec integrados para a troca e isolamento de ambientes.

---

### 🟢 FASE 3: Contas Bancárias e Cartões de Crédito
> **Objetivo:** Permitir o cadastro e gestão de contas bancárias e cartões vinculados.

- [ ] **Task 3.1: Model e CRUD de `BankAccount`**
  - Migration para `bank_accounts` (name, account_id).
  - Validações no model `BankAccount` (presença de nome, escopo da conta ativa).
  - Interface CRUD com suporte a Turbo Frames/Modais no tema Obsidian.
  - Especificações RSpec para `BankAccount`.
- [ ] **Task 3.2: Model e CRUD de `CreditCard`**
  - Migration para `credit_cards` (name, limit, bank_account_id, account_id).
  - Regras de validação (vínculo obrigatório a uma conta bancária existente).
  - Form e visualização de limite total e utilizado no frontend.
  - Especificações RSpec para `CreditCard`.

---

### 🟢 FASE 4: Categorias e Centros de Custo
> **Objetivo:** Fornecer estrutura de classificação para transações financeiras.

- [x] **Task 4.1: Model e Seeding de `Category`**
  - Migration para `categories` (name, default, account_id).
  - Populate de categorias padrão no `db/seeds.rb` (ex: Alimentação, Moradia, Transporte, Lazer, Saúde, Educação, Salário).
  - CRUD para categorias personalizadas criadas pelo usuário.
  - Testes RSpec para `Category`.
- [x] **Task 4.2: Model e Seeding de `CostCenter`**
  - Migration para `cost_centers` (name, default, account_id).
  - Populate de centros de custo padrão no `db/seeds.rb` (ex: Pessoal, Trabalho, Projetos).
  - CRUD para novos centros de custo personalizados.
  - Testes RSpec para `CostCenter`.

---

### 🟢 FASE 5: Entradas e Saídas (Transações Financeiras)
> **Objetivo:** Permitir o registro, filtragem e acompanhamento do fluxo de caixa.

- [x] **Task 5.1: Modelagem da Entidade `Transaction`**
  - Migration para `transactions` (type: `income`/`expense`, amount, description, date, category_id, cost_center_id, bank_account_id, credit_card_id, account_id).
  - Regras de negócio e validações de valor, data e vínculos válidos.
  - Testes unitários em RSpec.
- [x] **Task 5.2: Interface de Lançamentos de Entradas e Saídas**
  - Formulário dinâmico (com opção de associar a conta bancária ou cartão de crédito).
  - Listagem de transações com ordenação por data, badges de tipo (receita em verde `#34d399`, despesa em vermelho `#ef4444`).
  - Filtros por período, categoria, centro de custo e conta bancária via Turbo Streams.
  - Especificações de sistema (Feature Specs) em RSpec.

---

### 🟢 FASE 6: Dashboard Inicial e Consolidação
> **Objetivo:** Entregar uma visão geral imediata do saldo e gastos do ambiente selecionado.

- [ ] **Task 6.1: Dashboard Financeiro Inicial**
  - Card de Saldo Total Consolidado por conta bancária.
  - Resumo de Entradas vs Saídas do mês atual.
  - Feed das últimas transações recentes.
- [ ] **Task 6.2: Refinamento de UX/UI e Polimento Visual**
  - Garantir aderência estrita às diretrizes de UI (Obsidian High-Contrast Dark).
  - Adicionar micro-animações, estados de hover e estados de foco acessíveis.
