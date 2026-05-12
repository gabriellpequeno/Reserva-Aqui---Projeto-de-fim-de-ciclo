# PRD — dark-mode-and-visual-bugs

## Contexto

O app ReservaAqui possui suporte a dark mode e um widget `CustomAppBar` reutilizável, mas a adoção desses recursos é inconsistente: diversas telas ignoram o tema ativo e usam cores fixas (hardcoded), enquanto headers são construídos de forma ad-hoc em cada tela com tamanhos, ícones e logotipos distintos. Isso resulta em quebra de dark mode e ausência de identidade visual unificada.

## Problema

1. **Dark mode incompleto:** Scaffolds, textos, ícones e toasts em múltiplas telas usam `Color(0xFF...)`, `Colors.white` ou `Colors.black` diretamente, ignorando `theme.colorScheme`.
2. **Headers não padronizados:** Cada tela implementa seu próprio header com tamanho de fonte (12–20px), peso (w400–w700), border radius (27 vs 30), ícone de voltar (3 variantes) e ícone de notificação (2 variantes) diferentes.
3. **Logo sem detecção de tema:** 10 telas hardcoded com `logoDark.svg` ou `logo.svg`; apenas `CustomAppBar` e `search_page` fazem detecção de tema dinamicamente.
4. **Bugs visuais isolados:** Formulários despadronizados, feedbacks ausentes, dados não carregados e conteúdo placeholder em produção.

## Público-alvo

- Usuários finais (perfil User) que utilizam dark mode no dispositivo
- Anfitriões (perfil Hotel) que gerenciam quartos e agendamentos
- Administradores (perfil Admin) que acessam o dashboard e a listagem de clientes

---

## Requisitos Funcionais

### 1. Padronização de Headers

> **Padrão a seguir:** `CustomAppBar` existente em `lib/core/widgets/custom_app_bar.dart`.
> Todas as telas devem usar ou estender esse widget. Os valores abaixo definem o padrão único.

| Elemento | Valor padrão |
|----------|-------------|
| Título | 20px, `FontWeight.w700`, cor `colorScheme.onPrimary` |
| Border radius do container | 27 |
| Ícone de voltar | `Icons.arrow_back_ios_new`, tamanho 24, cor `colorScheme.onPrimary` |
| Ícone de notificação | `Icons.notifications_none`, tamanho 24, cor `colorScheme.onPrimary` |
| Logo (fundo primário) | `logoDark.svg` sempre que o fundo for `AppColors.primary`; usar detecção de tema quando o fundo for `colorScheme.surface` |

1. O header da tela **Checkout** (`checkout_page.dart`) deve usar o `CustomAppBar` com o padrão acima
2. O header da tela **Pagamento via WhatsApp** (`whatsapp_payment_page.dart`) deve usar o `CustomAppBar` com o padrão acima
3. O header da tela **Agendamentos** (`agendamentos_page.dart`) deve usar o `CustomAppBar` com o padrão acima (título "Agendamentos" no estilo padrão)
4. O header da tela **Meus Quartos** (`my_rooms_page.dart`) deve usar o `CustomAppBar` com o padrão acima
5. O header da tela **Tickets** (`tickets_page.dart`) deve usar o `CustomAppBar` com o padrão acima
6. O header da tela **Favoritos** (`favorites_page.dart`) deve usar o `CustomAppBar` com border radius corrigido para 27 (atualmente 30) e ícone de notificação com tamanho 24
7. O header da tela **Criação de Quarto** (`add_room_page.dart`) deve usar o `CustomAppBar` com o padrão acima; o ícone de notificação deve ser `Icons.notifications_none` (atualmente usa `Icons.notifications`)
8. O header da tela **Notificações** (`notifications_page.dart`) deve incluir o logotipo do ReservaAqui seguindo a lógica de detecção de tema do `CustomAppBar`
9. O header da tela **Gerenciamento de Contas** (Admin, `admin_account_management_page.dart`) deve usar `logoDark.svg` diretamente (fundo é `AppColors.primary`), eliminando o uso de `logo.svg` com `colorFilter` branco
10. O header da tela **Detalhes do Hotel** (`hotel_details_page.dart`, SliverAppBar) deve padronizar o ícone de voltar para `Icons.arrow_back_ios_new` tamanho 24 com `colorScheme.onPrimary`
11. O header do **Chat** (`chat_page.dart`) deve usar `Icons.chevron_left` substituído por `Icons.arrow_back_ios_new` tamanho 24
12. O header da tela **Detalhes do Agendamento** (`agendamento_detail_page.dart`) deve corrigir o ícone de voltar para `Icons.arrow_back_ios_new` tamanho 24

---

### 2. Dark Mode — Scaffold e Backgrounds

13. O `scaffoldBackgroundColor` da tela **Checkout** (`checkout_page.dart:62`) deve usar `colorScheme.surface` em vez de `Color(0xFFD9D9D9)`
14. O `scaffoldBackgroundColor` da tela **Minha Reserva / Ticket Público** (`public_ticket_page.dart:42`) deve usar `colorScheme.surface` em vez de `Color(0xFFD9D9D9)`
15. O `scaffoldBackgroundColor` da tela **Reserva Confirmada** (`reservation_success_page.dart:25`) deve usar `colorScheme.surface` em vez de `Color(0xFFD9D9D9)`
16. O `scaffoldBackgroundColor` da tela **Pagamento via WhatsApp** (`whatsapp_payment_page.dart:95`) deve usar `colorScheme.surface` em vez de `Color(0xFFD9D9D9)`
17. O `scaffoldBackgroundColor` do **Chat** (`chat_page.dart:90`) deve usar `colorScheme.surface` em vez de `Colors.white`

---

### 3. Dark Mode — Telas do Bug Report Original

18. A tela **Assistente** (sem login) deve aplicar as cores do tema ativo em todos os elementos
19. A tela **Check-in** (sem login) deve aplicar o dark mode corretamente
20. A tela **Reserva Confirmada** (sem login) deve aplicar o dark mode e exibir o logotipo/símbolo do ReservaAqui
21. A tela **Minha Reserva** (sem login) deve aplicar o dark mode corretamente
22. O ícone de favoritar na tela **Hotel** (perfil User) deve ter estado de hover respeitando o tema ativo
23. O toast/snackbar "link copiado" na tela **Quarto** deve aplicar as cores do tema ativo
24. A tela **Reservar** (perfil User) deve aplicar o dark mode em todos os seus elementos
25. O seletor de tipo de pagamento na tela **Reservar** deve ter hover respeitando o tema ativo
26. O **Dashboard** (perfil Hotel) deve aplicar o dark mode integralmente
27. A tela **Detalhes do Agendamento** (perfil Hotel) deve aplicar o dark mode
28. O **Dashboard** (perfil Admin) deve aplicar o dark mode integralmente

---

### 4. Dark Mode — Cores de Status Hardcoded

29. As cores de status **sucesso** (`Color(0xFF1E7A1E)`) usadas em `public_ticket_page.dart` e `whatsapp_payment_page.dart` devem ser definidas em `AppColors` com variante responsiva ao tema
30. As cores de status **erro/cancelado** (`Color(0xFFC0392B)`) usadas em `checkout_page.dart`, `public_ticket_page.dart`, `payment_bottom_sheet.dart` e `whatsapp_payment_page.dart` devem ser definidas em `AppColors` com variante responsiva ao tema
31. Os backgrounds de estado de erro (`Color(0xFFFDE8E8)`, rosa fixo) nas telas de checkout e pagamento devem usar `colorScheme.errorContainer` ou equivalente do tema

---

### 5. Bugs Visuais — Formulários e Componentes

32. Os inputs do formulário de criação de conta do **perfil Hotel** devem ter ícones, seguindo o padrão visual do formulário do perfil User
33. Os **Termos e Condições** do perfil Hotel devem usar o mesmo componente de bottom sheet (animação de baixo para cima) utilizado no perfil User
34. Os textos de **Termos de Uso**, **Privacidade** e **Sobre o App** (seção "Legal") devem exibir conteúdo real nos três perfis (User, Hotel, Admin)
35. O estado de hover do ícone de favoritar na tela **Quarto** (User e Admin) deve ter feedback visual correto (mudança de cor, preenchimento ou animação)

---

### 6. Bugs Visuais — Tela Reservar

36. O botão **"Finalizar Reserva"** deve ser o último elemento da tela de Reservar
37. Após confirmar o pagamento, deve ser exibida uma tela/estado de feedback informando "Reserva realizada — aguardando confirmação do hotel"

---

### 7. Bugs Visuais — Dados e Conteúdo

38. As **notas/avaliações** dos hotéis devem ser exibidas corretamente nos cards de resultado da tela Search
39. Os campos de nome na tela de **Perfil** devem ser exibidos em Title Case nos três perfis (User, Hotel, Admin)
40. As **fotos de perfil** de usuários e hotéis devem ser carregadas corretamente na tela de Clientes (perfil Admin), com fallback para avatar padrão

---

### 8. Bugs Visuais — Tela de Agendamentos (Hotel)

41. Os **filtros horizontais** da tela de Agendamentos devem ter indicador visual de scroll horizontal quando houver mais itens do que o espaço disponível
42. Os **dias com agendamentos** devem ser destacados com cor diferente no calendário
43. O header **"Agendamentos"** deve seguir o estilo padrão definido na seção 1 acima

---

### 9. Bugs Visuais — Tela de Criação de Quarto (Hotel)

44. Ao clicar em uma comodidade na tela de **Criação de Quarto**, não deve ocorrer rebuild global da página; isolar estado em widget ou provider dedicado
45. O header **"Novo Quarto"** deve seguir o estilo padrão definido na seção 1 acima
46. O ícone de notificações na tela de **Criação de Quarto** deve ser padronizado para `Icons.notifications_none` (atualmente usa `Icons.notifications`)

---

## Requisitos Não-Funcionais

- [ ] **Consistência de tema:** nenhum valor de cor deve ser hardcoded nas telas e componentes corrigidos; usar exclusivamente tokens de `theme.colorScheme`, `ThemeData` ou `AppColors`
- [ ] **Centralização de AppBar:** todas as telas devem usar `CustomAppBar` ou estendê-lo — não implementar headers ad-hoc por página
- [ ] **Performance:** a correção do re-render na tela de Criação de Quarto não deve introduzir rebuilds adicionais
- [ ] **Acessibilidade:** feedbacks visuais (hover, toast, bottom sheet) devem manter contraste adequado tanto em light mode quanto em dark mode
- [ ] **Responsividade:** todas as correções devem funcionar nos tamanhos de tela suportados pelo app (mobile)

---

## Critérios de Aceitação

- Dado que o dispositivo está em dark mode, quando navegando por qualquer tela dos requisitos 18–31, então todos os elementos (fundo, texto, ícones, inputs, botões) devem refletir o tema escuro sem cores fixas visíveis
- Dado que o usuário não está autenticado, quando acessa a tela de Reserva Confirmada, então o logotipo deve ser exibido e o dark mode deve ser aplicado
- Dado que qualquer tela do app é aberta, quando o header é exibido, então o ícone de voltar deve ser `Icons.arrow_back_ios_new` (24px), o ícone de notificação deve ser `Icons.notifications_none` (24px) e o título deve ter 20px w700 — sem exceções entre telas
- Dado que o app está em dark mode e uma tela com fundo `colorScheme.surface` é aberta, quando o logo é exibido no header, então deve aparecer a variante correta do logo (claro em fundo escuro, escuro em fundo claro)
- Dado que o scaffold de qualquer tela é renderizado, quando o tema é alternado entre light e dark, então o fundo deve mudar de acordo com `colorScheme.surface` — sem fundos cinza ou brancos fixos
- Dado que o usuário está no formulário de criação de conta do perfil Hotel, quando visualiza os campos de input, então ícones devem estar presentes seguindo o mesmo padrão do perfil User
- Dado que o usuário clica em "Termos e Condições" no perfil Hotel, quando o componente é exibido, então deve animar de baixo para cima (bottom sheet), igual ao comportamento do perfil User
- Dado que o usuário acessa a seção "Legal" em qualquer perfil, quando lê os textos, então o conteúdo deve ser real e definitivo, sem placeholders
- Dado que o usuário está na tela Reservar, quando rola a página, então o botão "Finalizar Reserva" deve ser o último elemento visível
- Dado que o usuário confirma o pagamento, quando a ação é concluída, então deve ser exibido um feedback visual com a mensagem de aguardando confirmação do hotel
- Dado que os resultados da busca são carregados, quando os cards de hotel são exibidos, então a nota/avaliação deve aparecer em todos os cards
- Dado que o usuário acessa a tela de Perfil, quando o nome é exibido, então cada palavra deve ter a primeira letra em maiúscula (Title Case) nos três perfis
- Dado que o perfil Hotel acessa Agendamentos com mais filtros do que cabem na tela, quando visualiza os filtros horizontais, então deve haver indicador visual de scroll (gradiente, seta ou truncamento)
- Dado que o perfil Hotel acessa o calendário de Agendamentos, quando há dias com agendamentos, então esses dias devem ter destaque visual (cor diferente)
- Dado que o perfil Hotel clica em uma comodidade na tela de Criação de Quarto, quando o estado é atualizado, então a página não deve sofrer rebuild global nem flickering
- Dado que o perfil Admin acessa a tela de Clientes, quando a listagem é carregada, então as fotos de perfil devem ser exibidas; em caso de erro/ausência, um avatar padrão deve ser mostrado

---

## Mapa de Arquivos Afetados

| Arquivo | Problemas |
|---------|-----------|
| `checkout_page.dart` | Scaffold BG hardcoded, Colors.white no header, ícone voltar não-padrão |
| `public_ticket_page.dart` | Scaffold BG hardcoded, dark mode ausente |
| `reservation_success_page.dart` | Scaffold BG hardcoded, dark mode ausente, logo ausente |
| `whatsapp_payment_page.dart` | Scaffold BG hardcoded, ícone voltar não-padrão |
| `chat_page.dart` | Scaffold BG `Colors.white`, ícone voltar `chevron_left` |
| `agendamentos_page.dart` | Header título fora do padrão, dark mode ausente |
| `agendamento_detail_page.dart` | Ícone voltar não-padrão, dark mode ausente |
| `my_rooms_page.dart` | Header título fora do padrão (16px w500) |
| `tickets_page.dart` | Header padrão correto exceto logo hardcoded |
| `favorites_page.dart` | Border radius 30 (deveria ser 27), ícone notificação tamanho 20 |
| `add_room_page.dart` | Ícone notificação `Icons.notifications`, header título 12px w400, progress bar cores hardcoded |
| `notifications_page.dart` | Logo ausente no header |
| `admin_account_management_page.dart` | Logo com colorFilter em vez de `logoDark.svg` |
| `hotel_details_page.dart` | Ícone voltar não-padrão (20px, Colors.white) |
| `payment_bottom_sheet.dart` | Cores de status hardcoded |

---

## Fora de Escopo

- Redesign ou alteração da identidade visual (paleta de cores, tipografia, ícones além dos listados)
- Implementação de novos fluxos de reserva ou pagamento
- Integração com novos provedores de imagem ou armazenamento
- Criação de novos conteúdos para a seção "Legal" (redação é responsabilidade do time de produto/jurídico)
- Correções de bugs em telas não listadas neste documento
- Mudanças na lógica de negócio relacionada a agendamentos ou calendário além do destaque visual dos dias
- Criação de novos tokens de design system além dos necessários para as correções listadas
