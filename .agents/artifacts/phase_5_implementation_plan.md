# 📋 Plano de Implementação: FASE 5 — Entradas e Saídas (Transações Financeiras)

Este documento apresenta o plano detalhado de arquitetura, banco de dados, regras de negócio, interface e especificações para a **Fase 5** da aplicação **Petunia** (Sistema de Controle Financeiro Pessoal em Ruby on Rails).

---

## 🎯 Objetivo da Fase 5

Permitir o registro de lançamentos financeiros (`Transaction` - receitas e despesas), associação a categorias, centros de custo, contas bancárias ou cartões de crédito, além da filtragem em tempo real (por período, tipo, categoria, centro de custo e meio de pagamento) via Turbo Streams e visualização no padrão *Obsidian Dark*.

---

## ⚠️ User Review Required

> [!IMPORTANT]
> **Regras de Negócio & Meios de Pagamento:**
> * **Receitas (`income`):** Devem ser obrigatoriamente vinculadas a uma **Conta Bancária** (`bank_account`). Cartões de crédito não podem ser selecionados para receitas.
> * **Despesas (`expense`):** Podem ser pagas via **Conta Bancária** (`bank_account`) ou **Cartão de Crédito** (`credit_card`). Deve haver exatamente um meio de pagamento associado.
> * **Data e Valor:** O valor deve ser obrigatoriamente positivo (`> 0`) e a data padrão sugerida no formulário é a data atual (`Date.current`).
> * **Segurança Multi-Tenant:** Todas as entidades associadas (Categoria, Centro de Custo, Conta Bancária e Cartão de Crédito) são validadas para garantir que pertencem ao mesmo ambiente (`account_id`) da transação.

---

## ❓ Open Questions

Nenhuma dúvida impeditiva no momento. Todas as premissas seguem os padrões estabelecidos no mapa de requisitos do projeto.

---

## 🛠️ Proposed Changes

### Database & Migrations

#### [NEW] `db/migrate/20260810125500_create_transactions.rb`
Criar a tabela `transactions`:
- `transaction_type` (string, `null: false`) — valores: `income`, `expense`
- `amount` (decimal, `precision: 10, scale: 2`, `null: false`)
- `description` (string, `null: false`)
- `date` (date, `null: false`)
- `account` (references, `null: false`, `foreign_key: true`)
- `category` (references, `null: false`, `foreign_key: true`)
- `cost_center` (references, `null: true`, `foreign_key: true`)
- `bank_account` (references, `null: true`, `foreign_key: true`)
- `credit_card` (references, `null: true`, `foreign_key: true`)
- Índices para performance:
  - `[:account_id, :date]`
  - `[:account_id, :transaction_type]`
  - `[:account_id, :category_id]`

---

### Models & Associations

#### [NEW] `app/models/transaction.rb`
```ruby
class Transaction < ApplicationRecord
  enum :transaction_type, { income: "income", expense: "expense" }

  belongs_to :account
  belongs_to :category
  belongs_to :cost_center, optional: true
  belongs_to :bank_account, optional: true
  belongs_to :credit_card, optional: true

  validates :description, :date, :amount, :transaction_type, presence: true
  validates :amount, numericality: { greater_than: 0 }
  
  validate :must_have_valid_payment_source
  validate :same_account_associations

  private

  def must_have_valid_payment_source
    if income? && bank_account_id.blank?
      errors.add(:bank_account_id, "é obrigatória para lançamentos de receita")
    elsif expense? && bank_account_id.blank? && credit_card_id.blank?
      errors.add(:base, "Informe uma Conta Bancária ou um Cartão de Crédito como forma de pagamento")
    elsif income? && credit_card_id.present?
      errors.add(:credit_card_id, "não pode ser utilizado para lançamentos de receita")
    end
  end

  def same_account_associations
    return unless account_id

    errors.add(:category, "inválida para esta conta") if category && category.account_id != account_id
    errors.add(:cost_center, "inválido para esta conta") if cost_center && cost_center.account_id != account_id
    errors.add(:bank_account, "inválida para esta conta") if bank_account && bank_account.account_id != account_id
    errors.add(:credit_card, "inválido para esta conta") if credit_card && credit_card.account_id != account_id
  end
end
```

#### [MODIFY] `app/models/account.rb`
Adicionar associação `has_many :transactions, dependent: :destroy`.

#### [MODIFY] `app/models/category.rb`, `app/models/cost_center.rb`, `app/models/bank_account.rb`, `app/models/credit_card.rb`
Adicionar associações `has_many :transactions`.

---

### Controllers & Stimulus JS

#### [NEW] `app/controllers/transactions_controller.rb`
Ações `index`, `new`, `create`, `edit`, `update`, `destroy`.
A ação `index` aceitará parâmetros de filtro (`month`, `transaction_type`, `category_id`, `cost_center_id`, `payment_source`) e responderá em formato HTML e Turbo Stream para atualizações dinâmicas na listagem e nos cards de resumo.

#### [NEW] `app/javascript/controllers/transaction_form_controller.js`
Controlador Stimulus para alternar visibilidade e habilitação do campo de Cartão de Crédito dinamicamente quando o usuário alterna entre **Receita** (`income`) e **Despesa** (`expense`).

---

### Views & Components (Obsidian Dark UI)

#### [NEW] `app/views/transactions/index.html.erb`
- Cards superiores de resumo: **Total Receitas** (`#34d399`), **Total Despesas** (`#ef4444`), **Saldo do Período** (`#a78bfa`).
- Barra de filtros com busca por período (mês atual por padrão), tipo, categoria e conta.
- Lista/Tabela de transações com badges de tipo, ícones do meio de pagamento, categoria e botões de ação.

#### [NEW] `app/views/transactions/index.turbo_stream.erb`
- Atualização reativa da lista de transações e dos totais ao filtrar.

#### [NEW] `app/views/transactions/new.html.erb`, `edit.html.erb`, `_form.html.erb`
- Formulário estilizado no padrão Obsidian Dark com seletor dinâmico de tipo e fontes de pagamento.

#### [MODIFY] `app/views/shared/_header.html.erb`
- Adicionar link **Transações** na navegação principal.

---

### Localization (i18n)

#### [MODIFY] `config/locales/pt-BR.yml` & `config/locales/en.yml`
Adicionar traduções completas para a entidade `Transaction`, tipos (`Receita`, `Despesa`), filtros, totais do período e validações.

---

### RSpec Tests & Factories

#### [NEW] `spec/factories/transactions.rb`
#### [NEW] `spec/models/transaction_spec.rb`
#### [NEW] `spec/requests/transactions_spec.rb`

---

## 🧪 Verification Plan

### Automated Tests
Executar a suíte de testes unitários e de requisição:
```bash
bundle exec rspec spec/models/transaction_spec.rb spec/requests/transactions_spec.rb
```
Em seguida, executar a suíte completa de testes:
```bash
bundle exec rspec
```

### Manual Verification
1. Fazer login e navegar até **Transações**.
2. Criar uma nova **Receita** vinculando a uma Conta Bancária.
3. Criar uma nova **Despesa** vinculando a um Cartão de Crédito.
4. Testar a alternância dos filtros (por mês, tipo e categoria) e verificar a atualização dos cards de totais e da lista.
5. Editar e excluir transações.
