# PRD — login-page

## Contexto

O app ReservAqui possui uma tela de login (`lib/features/auth/presentation/pages/login_page.dart`) com campos de e-mail e senha, mas sem nenhuma lógica real: o botão "Login" executa apenas `context.go('/home')` (mock). A tela serve tanto hóspedes quanto anfitriões e é acessada via `/auth/login` a partir de `UserOrHostPage` — que já separa os dois roles no fluxo de cadastro, mas não os separa no fluxo de login.

O `AuthService` já possui `loginHotel()`, mas não possui `loginGuest()`. Nenhum dos dois é chamado pela tela atualmente.

## Problema

O usuário não consegue se autenticar de verdade porque:

1. `LoginPage` é `StatelessWidget` sem controllers nem `FormKey` — impossível capturar ou validar os campos.
2. O botão "Login" bypassa a API e navega diretamente para `/home`, ignorando credenciais.
3. Não há mecanismo para saber qual role está logando: a mesma rota `/auth/login` serve hóspedes e anfitriões, e os endpoints são distintos (`POST /usuarios/login` vs `POST /hotel/login`).
4. Erros da API (401, 429) não são tratados — o usuário não recebe nenhum feedback.
5. `AuthService` não tem método `loginGuest()` para o endpoint `POST /usuarios/login`.

## Público-alvo

Hóspedes e anfitriões já cadastrados que desejam acessar suas contas no ReservAqui.

## Requisitos Funcionais

1. `UserOrHostPage` (rota `/auth`) deve passar o role selecionado para a `LoginPage` ao navegar para `/auth/login` — via GoRouter `extra: {'role': 'guest'}` ou `extra: {'role': 'host'}`.
2. `LoginPage` deve receber e armazenar o role vindo do `extra` do GoRouter. Se nenhum role for fornecido (acesso direto à rota), usar `'guest'` como padrão.
3. A tela deve ter `GlobalKey<FormState>` com dois campos: `email` e `senha` com controllers e validators.
4. Ao submeter, o sistema deve chamar o endpoint correspondente ao role recebido:
   - `guest` → `POST /usuarios/login`
   - `host` → `POST /hotel/login`
5. O body das requisições deve ser `{ "email": <valor>, "senha": <valor> }`.
6. Em caso de sucesso, o sistema deve:
   - Persistir a sessão via `AuthNotifier.setAuth(accessToken, refreshToken, AuthRole)` com o role correto.
   - Redirecionar para `/home`.
7. O botão de submit deve exibir `CircularProgressIndicator` durante o loading e bloquear múltiplos envios.
8. O sistema deve exibir SnackBar com mensagem amigável nos seguintes erros:
   - 401 → `"E-mail ou senha incorretos."`
   - 429 → `"Muitas tentativas. Aguarde alguns minutos e tente novamente."`
   - Genérico → `"Erro no servidor. Tente novamente mais tarde."`
9. `AuthService` deve receber um novo método `loginGuest(email, senha)` → `AuthResponse`.
10. O botão "cadastre-se agora" da `LoginPage` deve navegar para `/auth` (`UserOrHostPage`).
11. Os botões "Continue with Google" e "Continue with Apple" e o separador "ou" entre eles devem ser removidos da UI — login social está fora de escopo nesta entrega.
12. O ícone de perfil na navbar (`MainLayout._navigateToProfile`), quando o usuário **não está autenticado**, deve redirecionar para `/auth/login` em vez de `/auth` — a `LoginPage` é o ponto de entrada correto para usuários não autenticados; o cadastro fica acessível via botão "cadastre-se agora" dentro dela.

## Requisitos Não-Funcionais

- [ ] Segurança: campo `senha` com `isPassword: true` (texto oculto); senha nunca logada.
- [ ] Responsividade: `SingleChildScrollView` mantido para telas pequenas.
- [ ] UX: loading visível; botão desabilitado durante submit; feedback de erro por SnackBar.
- [ ] Consistência: seguir padrão `ConsumerStatefulWidget` + try/catch/finally já estabelecido em `UserSignUpPage` e `HostSignUpPage`.

## Critérios de Aceitação

- Dado que o hóspede chegou na `LoginPage` com role `guest`, preenche e-mail e senha válidos e toca "Login", então `POST /usuarios/login` é chamado, `setAuth` persiste role `AuthRole.guest` e o app navega para `/home`.
- Dado que o anfitrião chegou na `LoginPage` com role `host`, preenche credenciais válidas e toca "Login", então `POST /hotel/login` é chamado, `setAuth` persiste role `AuthRole.host` e o app navega para `/home`.
- Dado que as credenciais são inválidas, quando a API responde 401, então SnackBar `"E-mail ou senha incorretos."` é exibido e a tela permanece aberta.
- Dado que o backend aplica rate limiting, quando a API responde 429, então SnackBar `"Muitas tentativas. Aguarde alguns minutos e tente novamente."` é exibido.
- Dado que o formulário está incompleto, quando o usuário toca "Login", então erros inline aparecem nos campos e nenhuma chamada à API é realizada.
- Dado que o submit está em andamento, quando o usuário toca novamente "Login", então o toque é ignorado (botão substituído por loading).
- Dado que o usuário abre a `LoginPage`, então os botões de Google e Apple e o separador "ou" não são exibidos.
- Dado que o usuário não está autenticado e toca o ícone de perfil na navbar, então é redirecionado para `/auth/login` (LoginPage) e não para `/auth` (UserOrHostPage).

## Fora de Escopo

- Login com Google / Apple — botões removidos da UI; implementação de SSO é feature futura.
- Botão "Esqueci a senha" — endpoint não existe no backend; não será adicionado nesta feature.
- Diferenciação de layout/tela por role (guest e host usam a mesma `LoginPage`).
- Refresh automático de token (já coberto pelo interceptor do P0).
- Admin login (role admin não existe no app mobile).

## Contrato de API

| Método | Rota | Auth | Body | Resposta sucesso |
|--------|------|------|------|-----------------|
| POST | `/usuarios/login` | ❌ | `{ email, senha }` | 200 `{ data: usuario, tokens: { accessToken, refreshToken } }` |
| POST | `/hotel/login` | ❌ | `{ email, senha }` | 200 `{ data: hotel, tokens: { accessToken, refreshToken } }` |

### Erros esperados

| Status | Significado | Mensagem ao usuário |
|--------|-------------|---------------------|
| 401 | Credenciais incorretas | "E-mail ou senha incorretos." |
| 429 | Rate limit atingido | "Muitas tentativas. Aguarde alguns minutos e tente novamente." |
| 5xx | Erro interno | "Erro no servidor. Tente novamente mais tarde." |

## Arquivos a Criar / Modificar

| Ação | Arquivo | Descrição |
|------|---------|-----------|
| Modificar | `lib/features/auth/presentation/pages/login_page.dart` | Converter para `ConsumerStatefulWidget`; controllers, Form, loading, chamada real à API por role |
| Modificar | `lib/features/auth/presentation/pages/user_or_host_page.dart` | Adicionar botões de login para hóspede e anfitrião passando `extra: {'role': ...}` ao navegar para `/auth/login` |
| Modificar | `lib/features/auth/data/services/auth_service.dart` | Adicionar `loginGuest(email, senha)` → `AuthResponse` |
| Modificar | `lib/core/layouts/main_layout.dart` | Alterar redirect de não-autenticado de `/auth` para `/auth/login` em `_navigateToProfile` |

## Dependências

- **Requer:** P0 (`AuthNotifier`, `DioClient`) — já concluído
- **Requer:** P1-B ou P1-C — contas de hóspede e anfitrião criadas para testes
- **Bloqueia:** todas as features P3+ que dependem de sessão autenticada
