# Spec — User Profile Page (P3-A)

## Referência
- **PRD:** `conductor/features/user-profile-page.prd.md`
- **Arquivo principal:** `Frontend/lib/features/profile/presentation/pages/user_profile_page.dart`
- **Branch:** `feat/user-profile-page-integration`

---

## Abordagem Técnica

Converter `UserProfilePage` de `StatelessWidget` para `ConsumerWidget` (Riverpod), introduzindo:

1. Um `UserProfileNotifier` (`AsyncNotifier<UserProfileModel>`) que dispara `GET /usuarios/me` automaticamente no primeiro `watch`
2. Um `UserProfileModel` (DTO) para deserializar a resposta tipada, em vez de trabalhar com `Map<String, dynamic>` cru
3. Reutilização de `usuarioServiceProvider` e seu método `getAutenticado()` já existente em `lib/utils/Usuario.dart` — sem duplicação de lógica de rede
4. Tratamento declarativo dos três estados Riverpod (`AsyncLoading`, `AsyncData`, `AsyncError`) diretamente no `build()` da página

O `ProfileHeader` já suporta `avatarUrl?` com fallback para ícone padrão — nenhuma alteração de widget é necessária para a foto de perfil.

---

## Componentes Afetados

### Backend
- Nenhum. O endpoint `GET /usuarios/me` já existe.

### Frontend

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | `lib/features/profile/presentation/pages/user_profile_page.dart` | Converter para `ConsumerWidget`; substituir dados hardcoded por `UserProfileModel`; adicionar estados de loading e erro com retry |
| **Novo** | `lib/features/profile/data/models/user_profile_model.dart` | DTO com `fromJson` para mapear a resposta de `/usuarios/me` |
| **Novo** | `lib/features/profile/presentation/providers/user_profile_provider.dart` | `UserProfileNotifier` + `userProfileProvider` |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| `ConsumerWidget` em vez de `ConsumerStatefulWidget` | A página não tem estado local mutável (sem form, sem controllers); `ConsumerWidget` é mais simples e suficiente |
| `AsyncNotifier<UserProfileModel>` para o notifier | Padrão já adotado no `AuthNotifier`; o `build()` async dispara o fetch automaticamente no primeiro `watch`, sem necessidade de `initState` |
| Reutilizar `usuarioServiceProvider.getAutenticado()` | O método já existe, já trata erros via `_handleDioError` e já foi validado pelo time — criar outro service seria duplicação |
| `UserProfileModel` com `fromJson` em vez de `Map<String, dynamic>` | Tipagem garante acesso seguro aos campos; facilita extensão para P3-C (edição) que precisará dos mesmos dados |
| `ref.invalidate(userProfileProvider)` no botão "tentar novamente" | Força novo fetch sem criar lógica extra; padrão Riverpod para retry de `AsyncNotifier` |
| Avatar sem nova dependência | `ProfileHeader` já usa `NetworkImage` com fallback para `Icons.person` quando `avatarUrl == null` — zero custo de pacote |

---

## Contratos de API

| Método | Rota | Body | Response (2xx) |
|--------|------|------|----------------|
| GET | `/usuarios/me` | — | `{ data: { id, nome_completo, email, cpf, numero_celular, foto_perfil, data_nascimento } }` |

### Erros esperados

| Status | Significado | Comportamento |
|--------|-------------|---------------|
| 401 | Token expirado | Interceptor P0 faz refresh; se falhar, redireciona para `/auth/login` |
| 5xx | Erro interno do servidor | `AsyncError` → exibe mensagem do `_handleDioError` + botão "Tentar novamente" |
| timeout | Sem conexão | `AsyncError` → "Tempo de conexão esgotado. Verifique sua internet." + retry |

---

## Modelos de Dados

```dart
// lib/features/profile/data/models/user_profile_model.dart
class UserProfileModel {
  final String id;
  final String nomeCompleto;
  final String email;
  final String? cpf;
  final String? numeroCelular;
  final String? fotoPerfil;
  final String? dataNascimento;

  const UserProfileModel({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    this.cpf,
    this.numeroCelular,
    this.fotoPerfil,
    this.dataNascimento,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'].toString(),
      nomeCompleto: json['nome_completo'] as String,
      email: json['email'] as String,
      cpf: json['cpf'] as String?,
      numeroCelular: json['numero_celular'] as String?,
      fotoPerfil: json['foto_perfil'] as String?,
      dataNascimento: json['data_nascimento'] as String?,
    );
  }
}
```

---

## Fluxo de Execução

```
[Usuário navega para /profile/user]
       │
       ▼
[UserProfilePage.build() → ref.watch(userProfileProvider)]
       │
       ▼
[UserProfileNotifier.build() → usuarioServiceProvider.getAutenticado()]
       │
       ├─ AsyncLoading
       │       └─► Center(CircularProgressIndicator)
       │
       ├─ AsyncData(UserProfileModel)
       │       └─► ProfileHeader(
       │                 name: model.nomeCompleto,
       │                 email: model.email,
       │                 avatarUrl: model.fotoPerfil,   // null → ícone padrão
       │                 onEditTap: () => context.push('/profile/user/edit'),
       │             )
       │           + ProfileMenuSection('Atividade') — sem mudança
       │           + ProfileMenuSection('sistema')   — sem mudança
       │           + PrimaryButton('sair')           — sem mudança
       │
       └─ AsyncError(message)
               └─► Column(
                     Text(message),
                     ElevatedButton('Tentar novamente',
                       onPressed: () => ref.invalidate(userProfileProvider),
                     ),
                   )
```

---

## Dependências

**Bibliotecas (já no projeto):**
- [x] `flutter_riverpod` — `ConsumerWidget`, `AsyncNotifier`, `ref.watch`
- [x] `dio` — cliente HTTP via `dioProvider` (usado internamente pelo `usuarioServiceProvider`)
- [x] `go_router` — navegação para `/profile/user/edit` e `/profile/settings` já configurada no `app_router.dart`

**Outras features:**
- [x] P0 — `dio_client.dart` com interceptor de Bearer token e refresh automático de 401
- [x] P2-A — `authProvider` armazena o token que o interceptor injeta no header
- [x] `lib/utils/Usuario.dart` — `usuarioServiceProvider` com `getAutenticado()` já implementado

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Campo `id` retornado como `int` pelo backend em vez de `String` | `json['id'].toString()` no `fromJson` garante conversão segura independente do tipo |
| Campo `foto_perfil` retornando URL relativa (ex: `/uploads/foto.jpg`) | Verificar formato no primeiro teste de integração; se relativo, concatenar a base URL do `dioProvider` |
| Dado de perfil stale após logout + re-login | `userProfileProvider` não usa `keepAlive`; Riverpod destrói o notifier quando o widget sai do tree — novo login reinicia um `build()` limpo |
| Fetch disparado múltiplas vezes por rebuilds | `AsyncNotifier.build()` é chamado uma única vez por ciclo de vida do provider — Riverpod garante isso sem `initState` |
