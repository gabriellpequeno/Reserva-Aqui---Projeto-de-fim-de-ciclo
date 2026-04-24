# Plan — User Signup Page (P1-B)

> Derivado de: `conductor/specs/user-signup-page.spec.md`
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

> Sem novas dependências. Todos os pacotes (`dio`, `flutter_riverpod`, `go_router`,
> `shared_preferences`) já estão no `pubspec.yaml`.

- [x] Criar diretório `Frontend/lib/features/auth/data/models/`
- [x] Criar diretório `Frontend/lib/features/auth/data/services/`

---

## Frontend [CONCLUÍDO]

### 1. Models

- [x] **Criar** `lib/features/auth/data/models/register_request.dart`
- [x] **Criar** `lib/features/auth/data/models/auth_response.dart`

---

### 2. Service

- [x] **Criar** `lib/features/auth/data/services/auth_service.dart`

---

### 3. Página — Conversão para ConsumerStatefulWidget

- [x] **Modificar** `lib/features/auth/presentation/pages/user_signup_page.dart`

  **3.1 — Alterar declaração da classe**
  **3.2 — Adicionar imports e dependências**
  **3.3 — Declarar estado interno no `_UserSignUpPageState`**
  **3.4 — Envolver o `Column` principal em `Form`**
  **3.5 — Converter cada `AuthTextField` para usar controller + validator**
  **3.6 — Implementar método `_submit()`**
  **3.7 — Atualizar o `PrimaryButton` para refletir loading**

---

## Validação [PENDENTE]

- [ ] Executar `flutter analyze lib/` — zero erros (warnings pré-existentes permitidos)
- [ ] **Fluxo feliz:** preencher todos os campos válidos → tocar "Cadastrar" → loading aparece → redireciona para `/home`
  *(requer backend ativo ou mock de `AuthService`)*
- [ ] **409 Conflict:** cadastrar com e-mail já existente → SnackBar "Este e-mail já está cadastrado." aparece; formulário permanece na tela
- [ ] **400 Bad Request:** enviar payload inválido → SnackBar "Dados inválidos." aparece
- [ ] **Validação local — campo vazio:** tocar "Cadastrar" com campos em branco → erros inline aparecem nos campos sem disparar requisição
- [ ] **Validação local — senha divergente:** `confirmar senha` diferente → erro no campo sem disparar requisição
- [ ] **Validação local — senha curta:** senha com menos de 8 caracteres → erro no campo
- [ ] **Double-submit bloqueado:** tocar "Cadastrar" duas vezes rapidamente → somente uma requisição é disparada
- [ ] **`mounted` check:** navegar para fora da tela durante request → sem `setState after dispose` no console

---

## Regra de Atualização de Status

- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualizar o **Status geral** para `[CONCLUÍDO]`
e sincronizar com `conductor/plan.md`:
- Localizar bloco **"Fase 1 — Autenticação"**
- Marcar `[x]` na task: `- [ ] Tela de cadastro no app`
