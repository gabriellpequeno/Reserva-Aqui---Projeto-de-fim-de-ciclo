# BUG-4 — dark_mode - Correção de Telas Faltantes e Paleta de Cores

## Arquivos principais
`lib/core/theme/app_colors.dart`
`lib/core/theme/app_theme.dart`
`lib/features/chat/presentation/pages/chat_page.dart`
`lib/features/booking/presentation/pages/checkout_page.dart`
`lib/features/tickets/presentation/pages/tickets_page.dart`
`lib/features/tickets/presentation/pages/ticket_details_page.dart`
`lib/features/home/presentation/pages/home_page.dart`

## Prioridade
**Alta** — dark mode implementado na P6-A mas telas críticas ainda exibem cores hardcoded

## Branch sugerida
`fix/dark-mode-missing-screens`

---

## Contexto
A task P6-A implementou o dark mode no núcleo do app. Esta task corrige o que ficou faltando: telas que não receberam os tokens semânticos e a paleta de cores que precisa de ajuste.

---

## 1. Ajuste de Paleta

- [ ] **Substituir o cinza pelo azul escuro** no tema dark — o fundo/superfície no modo escuro deve usar um tom azulado (ex: `Color(0xFF0D1B2A)` ou similar) em vez do cinza neutro atual
- [ ] **Revisar a cor de destaque (accent)** — avaliar se o laranja atual mantém contraste suficiente sobre o azul escuro; se não, ajustar para uma variante com contraste AAA/AA (checar com `Color.computeLuminance()`)
- [ ] Os elementos que hoje usam azul como cor primária podem precisar de ajuste no dark mode para manter hierarquia visual — documentar a decisão no próprio `app_colors.dart` com um comentário curto
- [ ] **Regra:** Dark Mode = alto contraste — nenhum texto deve ter relação de contraste inferior a 4.5:1 sobre seu fundo

## 2. Telas sem Dark Mode aplicado

Para cada tela abaixo, substituir `Colors.*` e `AppColors.*` hardcoded por `Theme.of(context).colorScheme.*`:

- [ ] **chat_page.dart** — fundo do chat, balões de mensagem, input
- [ ] **checkout_page.dart** (tela de reserva) — fundo, cards de resumo, botões
- [ ] **Bottomsheet de pagamento** — identificar o widget/bottomsheet e aplicar tokens
- [ ] **tickets_page.dart** — fundo, cards de ticket, chips de status
- [ ] **ticket_details_page.dart** — fundo, seções de detalhe
- [ ] **Dashboard do Host** — identificar a página (`admin_profile_page.dart` ou `host_dashboard_page.dart`) e aplicar tokens

## 3. Fix de Imagem na Home Screen 1

- [ ] **Erro ao carregar imagem do slide 1** — verificar o path da imagem de fundo no slide introdutório da home
  - Provavelmente é um asset local com path errado (ex: `assets/images/` vs `assets/`)
  - Verificar `pubspec.yaml` → seção `flutter.assets` para confirmar o path registrado
  - Corrigir o path no widget ou registrar o asset correto no `pubspec.yaml`

---

## Critério de aceitação
- Ativar dark mode nas configurações → todas as telas listadas devem exibir fundo azulado escuro e textos com alto contraste
- Nenhum fundo branco ou cinza claro visível em nenhuma das telas listadas quando no dark mode
- A imagem da home screen 1 carrega sem erro tanto em light quanto em dark

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `app_colors.dart` | Ajustar tokens do dark: fundo azulado, revisar accent |
| `app_theme.dart` | `ColorScheme.dark` com as novas cores |
| `chat_page.dart` | Substituir hardcoded por tokens semânticos |
| `checkout_page.dart` | Idem |
| Bottomsheet de pagamento | Idem |
| `tickets_page.dart` | Idem |
| `ticket_details_page.dart` | Idem |
| Dashboard Host | Idem |
| `home_page.dart` | Corrigir path da imagem de fundo |

---

## Referência
- Task P6-A descreve o padrão de substituição: usar `Theme.of(context).colorScheme.*` e nunca `AppColors.*` diretamente nas telas
- Seguir o mesmo padrão documentado em P6-A para as telas faltantes
