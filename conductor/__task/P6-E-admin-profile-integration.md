# P6-E — admin-profile-integration
> Derivada de: `admin_profile_page.dart` + `edit_admin_profile_page.dart` — ambas 100% mock/estático

## Objetivo
Integrar a `AdminProfilePage` e a `EditAdminProfilePage` com dados reais do admin autenticado, seguindo o mesmo padrão já implementado para host (`host_profile_provider.dart`) e usuário (`user_profile_provider.dart`).

## Prioridade
**Média** — a página existe e é acessível, mas exibe dados hardcoded (`admin@admin.com`). Necessário para a demonstração do fluxo admin.

---

## Pré-condições (o que já existe, não refazer)

- `admin_profile_page.dart` — layout pronto, dados hardcoded
- `edit_admin_profile_page.dart` — formulário pronto, save com `Future.delayed` mock
- `host_profile_provider.dart` e `user_profile_provider.dart` — referência de padrão Riverpod
- `AuthNotifier` com `authProvider` — contém o token JWT do admin logado
- `DioClient` — interceptor Bearer já configurado

---

## O que precisa ser feito

### 1. Criar `admin_profile_provider.dart`
Caminho: `lib/features/profile/presentation/providers/admin_profile_provider.dart`

- [ ] `AdminProfileState` com campos: `nome`, `email`, `telefone` (opcionais: `departamento`, `permissoes`)
- [ ] `AdminProfileNotifier` (Riverpod `AsyncNotifier`) que chama `GET /api/usuarios/me` (ou endpoint admin equivalente)
- [ ] Provider exposto: `adminProfileProvider`

### 2. Converter `AdminProfilePage` para `ConsumerWidget`
- [ ] Substituir `StatelessWidget` por `ConsumerWidget`
- [ ] Consumir `adminProfileProvider` para exibir nome e e-mail reais no `ProfileHeader`
- [ ] Tratar loading, erro e retry (igual ao `HostProfilePage`)
- [ ] Corrigir `onPressed` do botão "sair" para usar `ref.read(authProvider.notifier).clear()` + `context.go('/auth/login')` (hoje usa `context.go('/auth')` sem limpar estado)

### 3. Integrar `EditAdminProfilePage` com backend
- [ ] Converter para `ConsumerStatefulWidget`
- [ ] Pré-preencher campos com dados do `adminProfileProvider`
- [ ] Substituir `Future.delayed` mock por chamada real: `PATCH /api/usuarios/me` (ou endpoint admin)
- [ ] Invalidar `adminProfileProvider` após save bem-sucedido
- [ ] Remover validação hardcoded de senha (`value != '123456'`)

### 4. Validação
- [ ] Admin faz login → `AdminProfilePage` exibe nome e e-mail reais
- [ ] Admin edita perfil → dados persistem no backend
- [ ] Logout limpa auth state e redireciona para login
- [ ] Dark Mode aplicado (tokens semânticos em vez de `AppColors.backgroundLight` fixo)

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `lib/features/profile/presentation/providers/admin_profile_provider.dart` | **Criar** |
| `lib/features/profile/presentation/pages/admin_profile_page.dart` | Converter para `ConsumerWidget`, consumir provider, corrigir logout |
| `lib/features/profile/presentation/pages/edit_admin_profile_page.dart` | Converter para `ConsumerStatefulWidget`, integrar backend, remover mock |

---

## Referência de padrão
- `host_profile_provider.dart` + `host_profile_page.dart` — seguir exatamente o mesmo padrão

## Bundle sugerido
**Fazer junto com P6-C (Admin Account Management)** — mesma pessoa já estará no contexto admin, providers e rotas admin.

## Dependências
- **Não bloqueia** outras tasks
- **Depende de:** endpoint `GET /api/usuarios/me` (ou equivalente admin) estar disponível no backend
