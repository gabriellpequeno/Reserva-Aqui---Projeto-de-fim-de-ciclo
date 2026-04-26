# Plan — Host Signup Page (P1-C)

> Derivado de: `conductor/specs/host-signup-page.spec.md`
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

> Sem novas dependências. Todos os pacotes (`dio`, `flutter_riverpod`, `go_router`,
> `shared_preferences`) já estão no `pubspec.yaml`.
> Diretórios `data/models/` e `data/services/` já existem (criados em P1-B).

- [x] Confirmar que `Frontend/lib/features/auth/data/models/` existe
- [x] Confirmar que `Frontend/lib/features/auth/data/services/auth_service.dart` existe

---

## Backend [CONCLUÍDO]

> Nenhum endpoint novo. `POST /hotel/register` e `POST /hotel/login` já existem e estão operacionais.

- [x] Verificar que `POST /hotel/register` responde 201 com `{ data: { hotel_id, nome_hotel, email, schema_name, criado_em } }`
- [x] Verificar que `POST /hotel/login` responde 200 com `{ data: hotel, tokens: { accessToken, refreshToken } }`

---

## Frontend [CONCLUÍDO]

### 1. Model — `RegisterHostRequest` [CONCLUÍDO]

- [x] **Criar** `lib/features/auth/data/models/register_host_request.dart`

---

### 2. Service — Adições em `AuthService` [CONCLUÍDO]

- [x] **Modificar** `lib/features/auth/data/services/auth_service.dart`

---

### 3. Página — Conversão para `ConsumerStatefulWidget` [CONCLUÍDO]

- [x] **Modificar** `lib/features/auth/presentation/pages/host_signup_page.dart`

---

## Validação [CONCLUÍDO]

- [x] Executar `flutter analyze lib/` — zero erros (warnings pré-existentes permitidos)
- [x] **Fluxo feliz:** preencher todos os campos obrigatórios com dados válidos → tocar "Cadastrar Hotel" → loading aparece → register + auto-login → redireciona para `/home`
- [x] **409 Conflict:** cadastrar com CNPJ ou e-mail já existente → SnackBar "Este CNPJ ou e-mail já está cadastrado."; formulário permanece na tela
- [x] **400 Bad Request:** enviar payload inválido (ex: senha fraca) → SnackBar "Dados inválidos. Verifique os campos."
- [x] **Validação local — campo obrigatório vazio:** tocar "Cadastrar Hotel" com campos em branco → erros inline aparecem; nenhuma requisição é disparada
- [x] **Validação local — CNPJ com dígitos insuficientes:** < 14 dígitos → erro inline no campo
- [x] **Validação local — CEP com dígitos insuficientes:** < 8 dígitos → erro inline no campo
- [x] **Validação local — UF inválida:** mais ou menos de 2 letras → erro inline no campo
- [x] **Validação local — senha fraca:** sem maiúscula, minúscula, `@` ou dígito → erro inline no campo
- [x] **Validação local — confirmar senha divergente:** texto diferente da senha → erro inline; nenhuma requisição disparada
- [x] **Double-submit bloqueado:** tocar "Cadastrar Hotel" duas vezes rapidamente → somente uma requisição é disparada
- [x] **mounted check:** navegar para fora da tela durante request → sem `setState after dispose` no console
- [x] **Campos opcionais:** completar cadastro sem preencher `complemento` e `descrição` → cadastro realizado com sucesso

---

## Regra de Atualização de Status

- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualizar o **Status geral** para `[CONCLUÍDO]`
e sincronizar com `conductor/plan.md`:
- Localizar bloco **"Fase 1 — Autenticação"**
- Marcar `[x]` na task: `- [x] Tela de cadastro no app` (caso ainda não esteja marcada)
- Adicionar sub-entry: `- [x] Tela de cadastro de anfitrião (P1-C) — plan: plans/host-signup-page.plan.md`
