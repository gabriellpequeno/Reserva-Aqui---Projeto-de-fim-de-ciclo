# Plan — Suporte Email Redirect

> Derivado de: conductor/specs/suporte-email-redirect.spec.md
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Adicionar `LSApplicationQueriesSchemes: [mailto]` no `ios/Runner/Info.plist`

---

## Backend [CONCLUÍDO]

Nenhuma task de backend.

---

## Frontend [CONCLUÍDO]

- [x] Criar `lib/core/constants/app_constants.dart` com a constante `kSupportEmail`
- [x] Criar `lib/features/profile/presentation/pages/support_page.dart` com botão de email usando `url_launcher`
- [x] Implementar fallback `SnackBar` quando não houver app de email no dispositivo

---

## Validação [PENDENTE]

- [ ] Tocar no botão de email — verificar se abre o app de email com destinatário, assunto e corpo pré-preenchidos
- [ ] Simular dispositivo sem app de email — verificar se `SnackBar` exibe `suporte@reservaqui.com`
- [ ] Verificar no iOS que `canLaunchUrl` não é bloqueado após a alteração no `Info.plist`
