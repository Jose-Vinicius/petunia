# 🚀 Walkthrough — FASE 4: Categorias e Centros de Custo

A **FASE 4** do projeto **Petunia** foi totalmente implementada e validada com sucesso!

---

## 📦 Alterações Realizadas

### 1. Banco de Dados & Models
- **Migrations**:
  - `20260810123500_create_categories.rb`: tabela `categories` (`name: string`, `default: boolean`, `account_id: references`, índice único `[account_id, name]`).
  - `20260810123501_create_cost_centers.rb`: tabela `cost_centers` (`name: string`, `default: boolean`, `account_id: references`, índice único `[account_id, name]`).
- **Models**:
  - `Category`: `belongs_to :account`, constante `DEFAULT_CATEGORIES` (*Alimentação, Moradia, Transporte, Lazer, Saúde, Educação, Salário*), validação de presença e unicidade escopada ao ambiente.
  - `CostCenter`: `belongs_to :account`, constante `DEFAULT_COST_CENTERS` (*Pessoal, Trabalho, Projetos*), validação de presença e unicidade escopada ao ambiente.
  - `Account`: associações `has_many :categories` e `has_many :cost_centers` com callback `after_create :seed_default_categories_and_cost_centers` para popular automaticamente os registros padrão com `default: true`.
- **Seeds (`db/seeds.rb`)**:
  - Garantia de popular categorias e centros de custo padrão de forma idempotente em todas as contas.

### 2. Controllers & Rotas
- `CategoriesController`: CRUD completo (`index`, `new`, `create`, `edit`, `update`, `destroy`) escopado ao `current_account`.
- `CostCentersController`: CRUD completo (`index`, `new`, `create`, `edit`, `update`, `destroy`) escopado ao `current_account`.
- Rotas de recursos adicionadas em `config/routes.rb`.

### 3. Interface Visual (Obsidian Dark UI)
- Header (`app/views/shared/_header.html.erb`): adicionados botões diretos de navegação para **Categorias** e **Centros de Custo**.
- Views de Categorias: `categories/index.html.erb`, `categories/new.html.erb`, `categories/edit.html.erb` com badges visuais indicando registros "Padrão" ou "Personalizada".
- Views de Centros de Custo: `cost_centers/index.html.erb`, `cost_centers/new.html.erb`, `cost_centers/edit.html.erb` com badges visuais.

### 4. Internacionalização (i18n)
- Traduções completas em Português (`pt-BR.yml`) e Inglês (`en.yml`) para títulos, mensagens flash, formulários, badges e modelos ActiveRecord.

---

## 🧪 Validação e Testes

### 1. Suíte de Testes RSpec
Todos os **105 testes** do projeto foram executados com **0 falhas**:
- `spec/models/category_spec.rb`: validações de presença, unicidade e escopo por ambiente.
- `spec/models/cost_center_spec.rb`: validações de presença, unicidade e escopo por ambiente.
- `spec/models/account_spec.rb`: verificação da criação automática de categorias e centros de custo padrão no `after_create`.
- `spec/requests/categories_spec.rb`: autenticação, CRUD completo e segurança multi-tenant.
- `spec/requests/cost_centers_spec.rb`: autenticação, CRUD completo e segurança multi-tenant.

### 2. Análise Estática (RuboCop)
- **70 arquivos inspecionados**, **0 ofensas detectadas**.
