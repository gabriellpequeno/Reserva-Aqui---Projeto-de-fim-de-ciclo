# PRD — Settings Page

## Contexto
A tela de configurações (`settings_page.dart`) já existe com UI completa: toggle de Dark Mode, toggle de Notificações e seção legal com tiles. Nenhum desses elementos possui comportamento real — não há persistência, integração com API nem navegação funcional.

## Problema
O usuário não consegue persistir preferências de tema, não consegue registrar/remover FCM token via toggle de notificações e os links legais não levam a nenhum lugar. A tela é visual mas inoperante.

## Público-alvo
Usuários autenticados (guest e host) que querem controlar preferências visuais, notificações e acessar informações legais do app.

## Requisitos Funcionais
1. O toggle de Dark Mode deve persistir a preferência via `shared_preferences` e aplicar o tema via `ThemeNotifier`
2. O toggle de Notificações deve registrar (`POST`) ou remover (`DELETE`) o FCM token no endpoint correto conforme a role (guest/host), detectada via `AuthNotifier`
3. A preferência de notificação deve ser persistida localmente via `shared_preferences`
4. Os tiles da seção Legal (Termos, Privacidade, Sobre) devem navegar para telas estáticas ou WebView

## Requisitos Não-Funcionais
- [ ] Segurança: todos os endpoints requerem autenticação
- [ ] Responsividade: funcionar em mobile (iOS e Android)
- [ ] Persistência local: `shared_preferences` para tema e notificações — sem chamadas de API para isso

## Critérios de Aceitação
- Dado que o usuário está na Settings, quando alternar o Dark Mode, então o tema muda imediatamente e persiste após reiniciar o app
- Dado que o usuário ativa Notificações, quando confirmar, então o FCM token é registrado na API e o toggle reflete o estado
- Dado que o usuário desativa Notificações, quando confirmar, então o FCM token é removido da API
- Dado que o usuário toca um tile legal, quando tocar, então abre a tela/WebView correspondente

## Fora de Escopo
- Desativação de conta (ver Questões Abertas abaixo)
- Sincronização de preferências de tema/notificação com backend
- Notificações por e-mail
- Configuração de FCM no backend (infra)

## Endpoints Usados

| Método | Rota                        | Auth | Descrição             |
|--------|-----------------------------|----- |-----------------------|
| POST   | `/dispositivos-fcm/usuario` | ✅   | Registrar FCM (guest) |
| DELETE | `/dispositivos-fcm/usuario` | ✅   | Remover FCM (guest)   |
| POST   | `/dispositivos-fcm/hotel`   | ✅   | Registrar FCM (host)  |
| DELETE | `/dispositivos-fcm/hotel`   | ✅   | Remover FCM (host)    |

## Questões Abertas

### ⚠️ Desativação de conta — adiada
A task original previa um botão "Desativar conta" com `DELETE /usuarios/me` (guest) e `DELETE /hotel/me` (host).

**Bloqueio identificado:** não está claro o comportamento da API quando há reservas ativas no momento do delete — se rejeita a requisição ou executa cascade. Isso impacta diretamente o texto do dialog de confirmação e o tratamento de erro no front.

**Decisão:** não implementar nesta entrega. Retomar quando o comportamento do backend estiver documentado ou testado.
