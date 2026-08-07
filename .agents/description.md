# 🌸 Petunia

A **Petunia** é uma aplicação financeira pessoal feita em Ruby on Rails para controle de **gastos, entradas e despesas**.
A ideia é oferecer uma solução simples e extensível para gerenciar fluxo de caixa pessoal ou de pequenos projetos.

---

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Tecnologias](#tecnologias)
- [Arquitetura](#arquitetura)
- [Funcionalidades](#funcionalidades)
- [Modelagem de Dados](#modelagem-de-dados)
- [Instalação e Configuração](#instalação-e-configuração)
- [Como Usar](#como-usar)
- [Roadmap](#roadmap)
- [Contribuição](#contribuição)
- [Licença](#licença)

---

## 🎯 Visão Geral

O **Petunia** nasceu da necessidade de ter uma ferramenta simples e extensível para controle financeiro pessoal.
Com ele é possível registrar entradas e saídas, organizá-las por categorias e centros de custo, e acompanhar o saldo em diferentes contas e cartões.

**Problema que resolve:** Dificuldade em acompanhar o fluxo de caixa pessoal de forma organizada e centralizada.

**Público-alvo:** Pessoas físicas e pequenos projetos que precisam de controle financeiro básico.

---

## 🛠 Tecnologias

| Camada | Tecnologia |
|---|---|
| Backend | Ruby on Rails |
| Banco de dados | PostgreSQL 17 |
| Frontend | Hotwire / Turbo / Stimulus _(a definir)_ |
| Autenticação | Devise _(a definir)_ |
| Testes | RSpec _(a definir)_ |

---

## ✨ Funcionalidades

### 🏦 Contas Bancárias e Cartões

- Cadastro de **contas bancárias** com nome
- Cadastro de **cartões de crédito**, sempre vinculados a uma conta bancária
  - Campos: nome, conta vinculada, limite total do cartão

### 🏷 Categorias e Centros de Custo

- Sistema pré-populado com categorias comuns (mercado, casa, transporte, lazer, etc.)
- Criação de **novas categorias** pelo usuário
- Criação de **novos centros de custo** pelo usuário

### 💸 Entradas e Saídas

- Registro de **entradas** (salário, ganhos extras, etc.)
- Registro de **saídas** (despesas fixas e variáveis)
- Vínculo de transações a categorias e centros de custo
- _(detalhes a expandir)_

### 📊 Relatórios _(planejado)_

- Saldo consolidado por conta
- Despesas por categoria
- Histórico mensal

---

## 🗄 Modelagem de Dados

### BankAccount (Conta Bancária)

| Campo | Tipo | Descrição |
|---|---|---|
| id | integer | Chave primária |
| name | string | Nome da conta |
| created_at | datetime | |
| updated_at | datetime | |

### CreditCard (Cartão de Crédito)

| Campo | Tipo | Descrição |
|---|---|---|
| id | integer | Chave primária |
| name | string | Nome do cartão |
| bank_account_id | integer | Conta vinculada (FK) |
| limit | decimal | Limite total do cartão |
| created_at | datetime | |
| updated_at | datetime | |

### Category (Categoria)

| Campo | Tipo | Descrição |
|---|---|---|
| id | integer | Chave primária |
| name | string | Nome da categoria |
| default | boolean | Se é uma categoria padrão do sistema |

### CostCenter (Centro de Custo)

| Campo | Tipo | Descrição |
|---|---|---|
| id | integer | Chave primária |
| name | string | Nome do centro de custo |
| default | boolean | Se é padrão do sistema |

### Transaction (Transação)

| Campo | Tipo | Descrição |
|---|---|---|
| id | integer | Chave primária |
| type | string | `income` (entrada) ou `expense` (saída) |
| amount | decimal | Valor |
| description | string | Descrição |
| date | date | Data da transação |
| category_id | integer | FK para Category |
| cost_center_id | integer | FK para CostCenter |
| bank_account_id | integer | FK para BankAccount (ou via cartão) |
| credit_card_id | integer | FK para CreditCard (opcional) |

---

## ⚙️ Instalação e Configuração

### Pré-requisitos

- Ruby `>= 3.x.x`
- Rails `>= 7.x.x`
- PostgreSQL 17

### Passo a passo

```bash
# Clone o repositório
git clone https://github.com/seu-usuario/petunia.git
cd petunia

# Instale as dependências
bundle install

# Configure o banco de dados
cp config/database.yml.example config/database.yml
# Edite o database.yml com suas credenciais

# Crie e migre o banco
rails db:create db:migrate db:seed

# Inicie o servidor
rails server
```

### Variáveis de Ambiente

```env
DATABASE_URL=postgres://localhost/petunia_development
# adicionar demais variáveis conforme necessário
```
---

## 🗺 Roadmap

### MVP
- [x] _(estrutura inicial)_
- [ ] Sistema de entradas e saídas funcional
- [ ] Cadastro de centros de custo e categorias
- [ ] Cadastro de contas bancárias e cartões

### Próximas Features
- [ ] Relatórios básicos (saldo, despesas por categoria, histórico mensal)
- [ ] Autenticação de usuários
- [ ] Suporte a múltiplos usuários
- [ ] Exportação de relatórios (CSV / PDF)
- [ ] Dashboard visual com gráficos
