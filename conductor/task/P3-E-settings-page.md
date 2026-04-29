# P3-E — settings_page - feat/account-settings

## Tela
`lib/features/profile/presentation/pages/settings_page.dart`

## Prioridade
**P3 — Perfil (Feature média)**

## Branch sugerida
`feat/settings-page-integration`

---

## Estado Atual
Tela implementada com UI completa. Já possui:
- Toggle de **Dark Mode** (CupertinoSwitch, detecta preferência do sistema no load)
- Toggle de **Notificações** (CupertinoSwitch)
- Seção legal com tiles (Termos, Privacidade, Sobre) com `onTap: () {}` vazios

Sem integração com API. Sem campo de desativação de conta.

---

## O que integrar

### Tema (Dark/Light Mode)
- [ ] Conectar o toggle de Dark Mode ao `ThemeNotifier` (ou provider equivalente) para persistir a preferência do usuário localmente via `shared_preferences`
- [ ] Não requer chamada de API — é configuração local

### Notificações
- [ ] Ao ativar: registrar FCM token → `POST /dispositivos-fcm/usuario` (guest) ou `POST /dispositivos-fcm/hotel` (host)
- [ ] Ao desativar: remover FCM token → `DELETE /dispositivos-fcm/usuario` ou `DELETE /dispositivos-fcm/hotel`
- [ ] Detectar role via `AuthNotifier` para usar o endpoint correto
- [ ] Persistir preferência local via `shared_preferences`

### Desativação de conta
- [ ] ⚠️ **Campo a criar na tela** — adicionar tile/botão "Desativar conta" na seção de configurações (ex: seção "Conta" separada das preferências visuais)
- [ ] Ao tocar: exibir dialog de confirmação com aviso claro sobre as consequências
- [ ] Guest: `DELETE /usuarios/me`
- [ ] Host: `DELETE /hotel/me`
- [ ] Após confirmar: limpar tokens e estado no `AuthNotifier`, redirecionar para tela inicial

### Seção Legal
- [ ] Implementar navegação nos `onTap` dos tiles (Termos, Privacidade, Sobre) — podem abrir WebView ou tela estática

---

## Endpoints usados

| Método | Rota                          | Auth | Descrição                       |
|--------|-------------------------------|------|---------------------------------|
| POST   | `/dispositivos-fcm/usuario`   | ✅   | Registrar FCM (guest)           |
| DELETE | `/dispositivos-fcm/usuario`   | ✅   | Remover FCM (guest)             |
| POST   | `/dispositivos-fcm/hotel`     | ✅   | Registrar FCM (host)            |
| DELETE | `/dispositivos-fcm/hotel`     | ✅   | Remover FCM (host)              |
| DELETE | `/usuarios/me`                | ✅   | Desativar conta guest           |
| DELETE | `/hotel/me`                   | ✅   | Desativar hotel                 |

---

## Dependências
- **Requer:** P0 (AuthNotifier com role), P2-A (autenticado)

## Bloqueia
— (folha)
