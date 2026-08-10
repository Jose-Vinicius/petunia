# 📋 Plano de Implementação: FASE 4 — Categorias e Centros de Custo

Este documento apresenta o plano detalhado de arquitetura, banco de dados, regras de negócio e especificações para a **Fase 4** da aplicação **Petunia** (Sistema de Controle Financeiro Pessoal em Ruby on Rails).

---

## 🎯 Objetivo da Fase 4

Fornecer a estrutura de classificação para transações financeiras através das entidades `Category` (Categorias) e `CostCenter` (Centros de Custo), permitindo o isolamento multi-tenant por ambiente (`Account`), auto-seeding de registros padrão e gerenciamento completo (CRUD) para registros personalizados.

---

## ⚠️ User Review Required

> [!IMPORTANT]
> **Estratégia Multi-Tenancy para Categorias e Centros de Custo Padrão:**
> Cada conta (`Account`) possuirá seus próprios registros de `Category` e `CostCenter`. No momento da criação de um ambiente (`Account`), um callback automático criará as categorias e centros de custo padrão marcados com `default: true`.
> 
> * **Categorias Padrão:** Alimentação, Moradia, Transporte, Lazer, Saúde, Educação, Salário.
> * **Centros de Custo Padrão:** Pessoal, Trabalho, Projetos.
> 
> Esta abordagem garante isolamento completo entre tenants e flexibilidade total para o usuário sem queries complexas ou riscos de vazamento entre ambientes.

---

## ❓ Open Questions

Nenhuma dúvida impeditiva no momento. Todas as diretrizes da Fase 4 seguem o padrão estabelecido nas fases 1, 2 e 3.

---

## 🛠️ Proposed Changes

### Database & Migrations

#### [NEW] `db/migrate/20260810123500_create_categories.rb`
Criar a tabela `categories`:
- `name` (string, `null: false`)
- `default` (boolean, `null: false, default: false`)
- `account` (references, `null: false, foreign_key: true`)
- Índice único composto: `[:account_id, :name]`

#### [NEW] `db/migrate/20260810123501_create_cost_centers.rb`
Criar a tabela `cost_centers`:
- `name` (string, `null: false`)
- `default` (boolean, `null: false, default: false`)
- `account` (references, `null: false, foreign_key: true`)
- Índice único composto: `[:account_id, :name]`

---

### Models & Callbacks

#### [NEW] `app/models/category.rb`
```ruby
class Category < ApplicationRecord
  DEFAULT_CATEGORIES = [
    "Alimentação", "Moradia", "Transporte", "Lazer", "Saúde", "Educação", "Salário"
  ].freeze

  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id, case_sensitive: false }
end
```

#### [NEW] `app/models/cost_center.rb`
```ruby
class CostCenter < ApplicationRecord
  DEFAULT_COST_CENTERS = [
    "Pessoal", "Trabalho", "Projetos"
  ].freeze

  belongs_to :account

  validates :name, presence: true, uniqueness: { scope: :account_id, case_sensitive: false }
end
```

#### [MODIFY] `app/models/account.rb`
Adicionar associações e callback de inicialização automática de categorias e centros de custo padrão:
```ruby
class Account < ApplicationRecord
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :bank_accounts, dependent: :destroy
  has_many :credit_cards, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :cost_centers, dependent: :destroy

  validates :name, presence: true

  after_create :seed_default_categories_and_cost_centers

  private

  def seed_default_categories_and_cost_centers
    Category::DEFAULT_CATEGORIES.each do |cat_name|
      categories.create!(name: cat_name, default: true)
    end

    CostCenter::DEFAULT_COST_CENTERS.each do |cc_name|
      cost_centers.create!(name: cc_name, default: true)
    end
  end
end
```

#### [MODIFY] `db/seeds.rb`
Garantir idempotência e popular categorias/centros de custo em contas já existentes sem duplicados.

---

### Controllers & Routes

#### [NEW] `app/controllers/categories_controller.rb`
Implementar ações `index`, `new`, `create`, `edit`, `update`, `destroy` escopadas ao `current_account`.

#### [NEW] `app/controllers/cost_centers_controller.rb`
Implementar ações `index`, `new`, `create`, `edit`, `update`, `destroy` escopadas ao `current_account`.

#### [MODIFY] `config/routes.rb`
Adicionar rotas de recursos:
```ruby
resources :categories, except: [ :show ]
resources :cost_centers, except: [ :show ]
```

---

### Views & Design System (Obsidian Dark)

#### [NEW] `app/views/categories/index.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb`
Exibir listagem de categorias com badges visuais indicando "Padrão" ou "Personalizada", botões de ação e modais/formulários de criação/edição.

#### [NEW] `app/views/cost_centers/index.html.erb`, `new.html.erb`, `edit.html.erb`, `_form.html.erb`
Exibir listagem de centros de custo com badges visuais, formulários de criação e edição.

#### [MODIFY] `app/views/shared/_header.html.erb`
Adicionar links na navegação superior para "Categorias" e "Centros de Custo".

---

### Localization (i18n)

#### [MODIFY] `config/locales/pt-BR.yml` & `config/locales/en.yml`
Adicionar chaves de tradução para `categories` e `cost_centers` (títulos, formulários, badges, mensagens flash e nomes de atributos ActiveRecord).

---

### RSpec Tests & Factories

#### [NEW] `spec/factories/categories.rb`
#### [NEW] `spec/factories/cost_centers.rb`
#### [NEW] `spec/models/category_spec.rb`
#### [NEW] `spec/models/cost_center_spec.rb`
#### [NEW] `spec/requests/categories_spec.rb`
#### [NEW] `spec/requests/cost_centers_spec.rb`

---

## 🧪 Verification Plan

### Automated Tests
Executar os testes RSpec em ambiente sandbox para verificar todas as regras de negócio:
```bash
bundle exec rspec spec/models/category_spec.rb spec/models/cost_center_spec.rb spec/requests/categories_spec.rb spec/requests/cost_centers_spec.rb
```
Em subterranean, executar a suíte de testes completa:
```bash
bundle exec rspec
```

### Manual Verification
1. Fazer login na aplicação e selecionar uma conta.
2. Navegar até a tela de **Categorias** e verificar a presença das categorias padrão (Alimentação, Moradia, Transporte, Lazer, Saúde, Educação, Salário).
3. Criar uma nova categoria personalizada.
4. Navegar até **Centros de Custo** e verificar os padrões (Pessoal, Trabalho, Projetos).
5. Criar um novo centro de custo personalizado.
