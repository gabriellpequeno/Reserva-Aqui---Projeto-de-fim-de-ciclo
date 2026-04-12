# Product Requirements Document (PRD) — ReservAqui

## 1. Introdução e Objetivo

## 2. Escopo do Projeto


### Fora do Escopo


---

## 3. Atores e Permissões

O sistema possui dois níveis de acesso baseados em roles (funções).

| Ator | Descrição | Permissões Chave |
| --- | --- | --- |
| **Cliente (Usuário Comum)** | Cliente que predente se hospedar | • Cadastrar-se e fazer login.
| --- | --- | --- |
| **Administrador (Atendente)** | Gerente ou funcionário do Hotel. | • Todas as permissões do Cliente.
| --- | --- | --- |

---

## 4. Requisitos Funcionais (Por Módulo)

### 4.1. Módulo de Autenticação (Auth)

### 4.2. Módulo de Usuários (Users)

### 4.4. Módulo de Serviços (Services)

### 4.5. Módulo de Agendamentos (Bookings)

---

## 5. Regras de Negócio e Validações

---

## 6. Requisitos Técnicos (Não Funcionais)

 
**Linguagem:** 


 
**Banco de Dados:** 


 
**Autenticação:** 


 
**Testes:** 


 
**Configuração:** 


* **Front-end:** 



---

## 7. Modelo de Dados Atual (SQLite)

O schema atual usado no projeto corresponde às tabelas criadas em `src/backend/database/init_master.sql` e `src/backend/database/init_tenant.sql`:

**Desenho das tabelas:**

---

## 8. Definição de Rotas da API 

### Auth



### Jobs / Services (Protegido: Admin escreve, Todos leem)


### Bookings (Protegido)



---

## 9. Critérios de Aceite para Entrega

