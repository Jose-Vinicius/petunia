# 📋 Plano de Implementação: FASE 6 — Dashboard Financeiro e Importação por Planilha

Este documento apresenta o plano detalhado de arquitetura, serviços, regras de negócio, interface visual e especificações para a **Fase 6** da aplicação **Petunia** (Sistema de Controle Financeiro Pessoal em Ruby on Rails).

---

## 🎯 Objetivo da Fase 6

Entregar uma visão consolidada do estado financeiro do ambiente através de um **Dashboard Financeiro** inteligente e oferecer a funcionalidade de **Importação em Lote por Planilha** (`CSV` / `Excel`), além do polimento visual no padrão *Obsidian Dark*.

---

## ⚠️ User Review Required

> [!IMPORTANT]
> **Funcionalidade de Importação via Planilha:**
> * **Formatos Aceitos:** Arquivos `.csv` e `.xlsx` (utilizando a gem `roo` para parsing seguro).
> * **Mapeamento Flexível de Colunas:** Suporte a cabeçalhos em Português e Inglês (ex: `Data`/`Date`, `Descrição`/`Description`, `Valor`/`Amount`, `Tipo`/`Type`, `Categoria`/`Category`, `Centro de Custo`/`Cost Center`).
> * **Tratamento de Valores e Moeda:** Reconhecimento automático de formatos numéricos brasileiros (ex: `1.500,50`, `R$ 1.500,50`, `-45,00`) e formatos internacionais (`1500.50`).
> * **Criação Automática de Categorias:** Caso a planilha informe uma categoria que ainda não existe na conta, o serviço criará a categoria automaticamente.
> * **Meio de Pagamento:** A planilha terá a conta de destino/cartão de credito no qual será lançada

---

## ❓ Open Questions

Nenhuma dúvida impeditiva no momento. A importação em lote e o dashboard seguem o design system *Obsidian Dark* e a arquitetura multi-tenant estabelecida.

---

## 🛠️ Proposed Changes

### Gems & Dependencies

#### [MODIFY] `Gemfile`
Adicionar a gem `roo` para parsing transparente de arquivos `.xlsx` e `.csv`:
```ruby
gem "roo", "~> 2.10"
```

---

### Services

#### [NEW] `app/services/transaction_importer_service.rb`
Serviço responsável por ler o arquivo enviado, validar colunas, criar transações e retornar estatísticas do lote importado:
```ruby
class TransactionImporterService
  def initialize(file:, account:, default_bank_account: nil, default_credit_card: nil)
    @file = file
    @account = account
    @default_bank_account = default_bank_account
    @default_credit_card = default_credit_card
  end

  def call
    # Parsing, normalização de cabeçalhos, categorização e salvamento em batch
  end
end
```

---

### Controllers & Routes

#### [NEW] `app/controllers/dashboard_controller.rb`
Controller responsável pela renderização dos indicadores, gráficos de distribuição de categorias, saldo consolidado por conta e feed de transações recentes.

#### [NEW] `app/controllers/imports_controller.rb`
Controller para renderizar o modal de upload de planilha e processar o formulário de importação via Turbo Stream / HTML.

#### [MODIFY] `app/controllers/home_controller.rb`
Redirecionar usuários autenticados da landing page inicial `/` diretamente para o `dashboard_path`.

#### [MODIFY] `config/routes.rb`
Adicionar rotas para `dashboard` e `imports`:
```ruby
get "dashboard" => "dashboard#index", as: :dashboard
resources :imports, only: [ :new, :create ]
```

---

### Views & Obsidian Dark UI

#### [NEW] `app/views/dashboard/index.html.erb`
- Card de Saldo Consolidado Total.
- Cards de Entradas, Saídas e Saldo do Mês Atual.
- Distribuição de Gastos por Categoria (barras visuais com porcentagens).
- Resumo de saldos por Conta Bancária e limite utilizado de Cartões de Crédito.
- Feed das últimas 5 transações com ação rápida.
- Botões de Ação Rápida: "+ Nova Receita", "+ Nova Despesa" e "📥 Importar Planilha".

#### [NEW] `app/views/imports/new.html.erb`, `_form.html.erb`
- Form modal em Turbo Frame (`turbo_frame_tag "modal"`) com campo de upload de arquivo (`.csv`/`.xlsx`), seleção da conta bancária/cartão de destino e instruções de colunas aceitas.

#### [MODIFY] `app/views/shared/_header.html.erb`
- Adicionar link de acesso rápido ao **Painel** (Dashboard) na barra de navegação.

#### [MODIFY] `app/views/transactions/index.html.erb`
- Adicionar botão **Importar Planilha** na barra de ações da página de transações.

---

### Localization (i18n)

#### [MODIFY] `config/locales/pt-BR.yml` & `config/locales/en.yml`
- Adicionar traduções para o Dashboard (indicadores, resumos, distribuição por categoria).
- Adicionar traduções para a tela e respostas de importação de planilha (sucesso, erros de parsing, formato inválido).

---

### RSpec Tests

#### [NEW] `spec/services/transaction_importer_service_spec.rb`
- Testes unitários para importação de CSV/XLSX, tratamento de valores brasileiros e de formato internacional, e auto-criação de categorias.

#### [NEW] `spec/requests/dashboard_spec.rb`
- Testes de requisição para cálculo dos totais e renderização do painel.

#### [NEW] `spec/requests/imports_spec.rb`
- Testes de upload de arquivos e resposta de erros.

---

## 🧪 Verification Plan

### Automated Tests
Executar a suíte de testes do importador e do dashboard:
```bash
bundle exec rspec spec/services/transaction_importer_service_spec.rb spec/requests/dashboard_spec.rb spec/requests/imports_spec.rb
```
Em seguida, executar toda a suíte de testes do projeto:
```bash
bundle exec rspec
```

### Manual Verification
1. Fazer login na aplicação e acessar a tela `/dashboard`.
2. Verificar se os totais consolidados e as barras de porcentagem por categoria refletem os lançamentos existentes.
3. Clicar no botão **Importar Planilha** e enviar uma planilha `.csv` de exemplo com despesas e receitas.
4. Confirmar o salvamento em lote e verificar a atualização automática no Dashboard e na página de Transações.
