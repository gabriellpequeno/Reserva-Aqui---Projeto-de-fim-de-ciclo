# Product Requirements Document (PRD) — Little's Petshop

## 1. Introdução e Objetivo

## 2. Escopo do Projeto


### Fora do Escopo


---

## 3. Atores e Permissões

O sistema possui dois níveis de acesso baseados em roles (funções).

| Ator | Descrição | Permissões Chave |
| --- | --- | --- |
| **Cliente (Usuário Comum)** | Dono do animal que deseja contratar serviços. | • Cadastrar-se e fazer login.

<br>

<br>• Cadastrar seus Pets.<br>

<br>• Visualizar serviços disponíveis.<br>

<br>• Agendar e cancelar serviços.<br>

<br>• Visualizar histórico de agendamentos. 

 |
| **Administrador (Atendente)** | Gerente ou funcionário do PetShop. | • Todas as permissões do Cliente.

<br>

<br>• Criar, editar e excluir Serviços.<br>

<br>• Visualizar todos os agendamentos.<br>

<br>• Registrar horários de início/término de serviços. 

 |

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

* 
**Linguagem:** 

* **Framework Web:** 
* 
**Banco de Dados:** 


* 
**Autenticação:** 


* 
**Testes:** 


* 
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

