# PRD — User Profile Page (get-guest-profile)

## Contexto
A tela de perfil do hóspede (`lib/features/profile/presentation/pages/user_profile_page.dart`) existe no app mas exibe dados hardcoded ou mockados. O backend já expõe o endpoint `GET /usuarios/me` para retornar os dados do usuário autenticado, e o interceptor de autenticação (P0) já está em funcionamento.

## Problema
O usuário autenticado não visualiza seus dados reais na tela de perfil. Sem integração com o backend, informações como nome, e-mail e foto são fictícias, prejudicando a confiança e a experiência do usuário.

## Público-alvo
Usuários hóspedes autenticados no aplicativo Reserva Aqui.

## Requisitos Funcionais
1. Ao entrar na tela, realizar `GET /usuarios/me` para buscar os dados do usuário autenticado.
2. Mapear a resposta da API para os widgets da tela (nome, e-mail, foto de perfil, etc.).
3. Criar `UserProfileNotifier` (Riverpod) para gerenciar e expor o estado do perfil.
4. Exibir indicador de carregamento (loading state) enquanto a requisição está em andamento.
5. Tratar erros de rede; erros 401 (token expirado) devem ser capturados pelo interceptor do P0.
6. O botão "Editar perfil" deve navegar para `edit_user_profile_page` (P3-C).
7. O botão "Configurações" deve navegar para `settings_page` (P3-E).
8. Exibir avatar padrão quando o backend não retornar URL de foto de perfil.

## Requisitos Não-Funcionais
- [ ] Segurança: requisição autenticada via Bearer token; refresh/logout tratado pelo interceptor P0
- [ ] Performance: feedback visual imediato (shimmer ou CircularProgressIndicator) durante o fetch
- [ ] Responsividade: funcionar corretamente em dispositivos móveis (Flutter)
- [ ] Resiliência: exibir mensagem de erro amigável em caso de falha de rede, com opção de tentar novamente

## Critérios de Aceitação
- Dado que o usuário está autenticado, quando abrir a tela de perfil, então deve ver seus dados reais (nome, e-mail) carregados do backend.
- Dado que a requisição está em andamento, quando a tela abrir, então deve exibir um indicador de carregamento.
- Dado que o backend não retorna foto de perfil, quando os dados forem carregados, então deve exibir um avatar padrão.
- Dado que ocorre erro de rede, quando a tela tentar carregar o perfil, então deve exibir mensagem de erro com opção de retry.
- Dado que o token está expirado (401), quando a requisição for feita, então o interceptor P0 deve redirecionar para o login.
- Dado que o usuário clica em "Editar perfil", quando na tela de perfil, então deve navegar para `edit_user_profile_page`.
- Dado que o usuário clica em "Configurações", quando na tela de perfil, então deve navegar para `settings_page`.

## Fora de Escopo
- Edição dos dados do perfil (cobre P3-C — `edit_user_profile_page`)
- Tela de configurações (cobre P3-E — `settings_page`)
- Upload ou alteração de foto de perfil
- Exclusão de conta
- Notificações por e-mail ou push relacionadas ao perfil
