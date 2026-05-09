# Spec — Suporte Email Redirect

## Referência
- **PRD:** conductor/features/suporte-email-redirect.prd.md

## Abordagem Técnica
Feature exclusivamente frontend. Usar `url_launcher` (já presente no pubspec `^6.3.1`) para abrir o app de email nativo via esquema `mailto:` com destinatário, assunto e corpo pré-preenchidos. A `support_page.dart` será criada seguindo o padrão das páginas vizinhas em `lib/features/profile/presentation/pages/`. O email de suporte será centralizado em um novo `app_constants.dart`. O `Info.plist` do iOS receberá a declaração do scheme `mailto` para que `canLaunchUrl` funcione corretamente.

## Componentes Afetados

### Backend
Nenhum.

### Frontend
- **Novo:** `SupportPage` (`lib/features/profile/presentation/pages/support_page.dart`)
- **Novo:** `AppConstants` (`lib/core/constants/app_constants.dart`) — constante `kSupportEmail`
- **Modificado:** `ios/Runner/Info.plist` — adicionar `LSApplicationQueriesSchemes` com `mailto`

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| Usar `url_launcher` | Já é dependência do projeto — evita código nativo adicional |
| Constante em `app_constants.dart` | Evita email hardcodado espalhado pelo código |
| `SnackBar` como fallback | Padrão Flutter para mensagens não-bloqueantes; não interrompe o fluxo |

## Contratos de API
Nenhum. Feature sem chamadas ao backend.

## Modelos de Dados
Nenhum. Feature sem persistência.

## Dependências

**Bibliotecas:**
- [x] `url_launcher ^6.3.1` — já presente no pubspec; abrir app de email via `mailto:`

**Configuração nativa:**
- [ ] `ios/Runner/Info.plist` — adicionar `LSApplicationQueriesSchemes: [mailto]` (atualmente ausente)

**Outras features:**
Nenhuma.

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| Dispositivo sem app de email configurado | Exibir `SnackBar` com `suporte@reservaqui.com` para cópia manual |
| iOS bloqueando `canLaunchUrl` sem scheme declarado | Adicionar `mailto` em `LSApplicationQueriesSchemes` no `Info.plist` |
