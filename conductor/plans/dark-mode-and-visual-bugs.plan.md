# Plan — dark-mode-and-visual-bugs

> Derivado de: `conductor/specs/dark-mode-and-visual-bugs.spec.md`
> Status geral: [PENDENTE]

---

## Setup & Infraestrutura [PENDENTE]

- [ ] Verificar se `lib/core/utils/` existe; criar pasta se necessário
- [ ] Confirmar com design/PO se `colorScheme.surface` (branco puro) é aceitável em light mode para substituir os fundos `Color(0xFFD9D9D9)` — ou se `colorScheme.surfaceContainerLow` é melhor
- [ ] Investigar endpoint `GET /hotels` (search): o campo `rating` está sendo retornado pela API? Registrar resultado antes de implementar req. 38
- [ ] Investigar endpoint de listagem de clientes (admin): o campo `profileImageUrl` está sendo retornado pela API? Registrar resultado antes de implementar req. 40
- [ ] Solicitar ao time de produto os textos reais de Termos de Uso, Privacidade e Sobre o App para a seção "Legal" (req. 34)

---

## Backend [PENDENTE]

> Nenhum endpoint novo ou modificado nesta entrega — feature 100% client-side.
> Correções de backend para `rating` e `profileImageUrl` (se necessárias) são bugs separados fora do escopo desta branch.

---

## Frontend [PENDENTE]

### 1. Tokens e utilitários compartilhados [PENDENTE]

- [ ] `lib/core/theme/app_colors.dart` — adicionar `successColor`, `successContainer`, `errorColor`, `errorContainer` (ver spec seção "Modelos de Dados")
- [ ] `lib/core/utils/string_extensions.dart` — criar arquivo com extension `toTitleCase()` na classe `String`

---

### 2. `CustomAppBar` — expansão [PENDENTE]

- [ ] `lib/core/widgets/custom_app_bar.dart` — adicionar parâmetro `title` (`String?`, default `null`): quando não-nulo, exibe texto 20px w700 `colorScheme.onPrimary` no centro em vez do logo
- [ ] `lib/core/widgets/custom_app_bar.dart` — adicionar parâmetro `showNotificationIcon` (`bool`, default `false`): quando `true`, exibe `Icons.notifications_none` tamanho 24 `colorScheme.onPrimary` à direita com `InkWell` navegando para `/notifications`

---

### 3. Scaffolds com background hardcoded [PENDENTE]

- [ ] `lib/features/booking/presentation/pages/checkout_page.dart` — `scaffoldBackgroundColor: Color(0xFFD9D9D9)` → `colorScheme.surface`
- [ ] `lib/features/booking/presentation/pages/public_ticket_page.dart` — `scaffoldBackgroundColor: Color(0xFFD9D9D9)` → `colorScheme.surface`
- [ ] `lib/features/booking/presentation/pages/reservation_success_page.dart` — `scaffoldBackgroundColor: Color(0xFFD9D9D9)` → `colorScheme.surface`
- [ ] `lib/features/booking/presentation/pages/whatsapp_payment_page.dart` — `scaffoldBackgroundColor: Color(0xFFD9D9D9)` → `colorScheme.surface`
- [ ] `lib/features/chat/presentation/pages/chat_page.dart` — `scaffoldBackgroundColor: Colors.white` → `colorScheme.surface`

---

### 4. Padronização de headers — migração para `CustomAppBar` [PENDENTE]

- [ ] `lib/features/bookings/presentation/pages/agendamentos_page.dart` — substituir header ad-hoc por `CustomAppBar(title: 'Agendamentos', showNotificationIcon: true)`
- [ ] `lib/features/bookings/presentation/pages/agendamento_detail_page.dart` — substituir header ad-hoc por `CustomAppBar`; ícone de voltar passa a ser `Icons.arrow_back_ios_new` 24px
- [ ] `lib/features/rooms/presentation/pages/my_rooms_page.dart` — substituir header ad-hoc por `CustomAppBar`; corrigir título para 20px w700
- [ ] `lib/features/tickets/presentation/pages/tickets_page.dart` — substituir header ad-hoc por `CustomAppBar`
- [ ] `lib/features/favorites/presentation/pages/favorites_page.dart` — substituir header ad-hoc por `CustomAppBar`; `borderRadius` 30 → 27 corrigido pelo widget padrão
- [ ] `lib/features/rooms/presentation/pages/add_room_page.dart` — substituir header ad-hoc por `CustomAppBar(showNotificationIcon: true)`; ícone de notificação usará `Icons.notifications_none` (padrão do widget)
- [ ] `lib/features/notifications/presentation/pages/notifications_page.dart` — adicionar `CustomAppBar` com logo (sem back button se for raiz, ou com back button se acessada via nav)
- [ ] `lib/features/profile/presentation/pages/admin_account_management_page.dart` — substituir `logo.svg` + `colorFilter` por `logoDark.svg` diretamente no header
- [ ] `lib/features/search/presentation/pages/hotel_details_page.dart` — corrigir ícone de voltar na SliverAppBar para `Icons.arrow_back_ios_new` tamanho 24

---

### 5. Dark mode — telas do bug report original [PENDENTE]

- [ ] Tela **Assistente** (chat/assistant) — substituir todas as cores hardcoded por `colorScheme.*`
- [ ] Tela **Check-in** (sem login) — substituir cores hardcoded por `colorScheme.*`
- [ ] Tela **Minha Reserva** (sem login, `public_ticket_page.dart`) — substituir cores hardcoded por `colorScheme.*` (fundo já corrigido no passo 3)
- [ ] Tela **Hotel Details** — hover do ícone de favoritar: usar `colorScheme.primaryContainer` no estado ativo
- [ ] Tela **Quarto** (`room_details_page.dart`) — toast "link copiado": usar `SnackBar(backgroundColor: colorScheme.inverseSurface)`
- [ ] Tela **Reservar** (`checkout_page.dart`) — substituir `Colors.white` em cards, dividers e textos internos por `colorScheme.*`; hover do seletor de pagamento
- [ ] Tela **Reservar** — `payment_bottom_sheet.dart`: substituir handle `Colors.grey.shade300`, fundo item selecionado `Colors.white`, estilos de texto cinza por `colorScheme.*`
- [ ] Dashboard **Hotel** — substituir cores hardcoded por `colorScheme.*` integralmente
- [ ] Tela **Detalhes do Agendamento** (Hotel) — substituir cores hardcoded por `colorScheme.*`
- [ ] Dashboard **Admin** — substituir cores hardcoded por `colorScheme.*` integralmente

---

### 6. Dark mode — cores de status [PENDENTE]

- [ ] `lib/features/booking/presentation/pages/checkout_page.dart` — substituir `Color(0xFFC0392B)` por `AppColors.errorColor`; `Color(0xFFFDE8E8)` por `colorScheme.errorContainer`
- [ ] `lib/features/booking/presentation/pages/public_ticket_page.dart` — substituir `Color(0xFF1E7A1E)` por `AppColors.successColor`; `Color(0xFFC0392B)` por `AppColors.errorColor`
- [ ] `lib/features/booking/presentation/pages/reservation_success_page.dart` — substituir `Color(0xFF1E7A1E)` por `AppColors.successColor`
- [ ] `lib/features/booking/presentation/pages/whatsapp_payment_page.dart` — substituir `Color(0xFF1E7A1E)` e `Color(0xFFC0392B)` por constantes de `AppColors`
- [ ] `lib/features/booking/presentation/widgets/payment_bottom_sheet.dart` — substituir cores de status e `Colors.grey.*` por `colorScheme.*` e `AppColors`

---

### 7. Bugs visuais — formulários e componentes [PENDENTE]

- [ ] Tela **Criação de Conta Hotel** (auth) — adicionar `prefixIcon` nos `TextFormField` seguindo o mesmo padrão (`Icons.*`) do formulário do perfil User
- [ ] Tela **Criação de Conta Hotel** — **Termos e Condições**: substituir overlay de página inteira por `showModalBottomSheet` com o mesmo componente `TermsBottomSheet` utilizado no perfil User
- [ ] Tela **Quarto** (`room_details_page.dart`) — ícone de favoritar: corrigir estado tap/pressed com `InkWell` + mudança de cor/preenchimento do ícone

---

### 8. Bugs visuais — tela Reservar [PENDENTE]

- [ ] `lib/features/booking/presentation/pages/checkout_page.dart` — reposicionar o botão "Finalizar Reserva" para o final da tela (último elemento do `Column`/`ListView`)
- [ ] `lib/features/booking/presentation/pages/checkout_page.dart` (ou nova tela/widget) — implementar estado de feedback pós-pagamento: modal, bottom sheet ou tela dedicada com mensagem "Reserva realizada — aguardando confirmação do hotel"

---

### 9. Bugs visuais — dados e conteúdo [PENDENTE]

- [ ] Tela **Search** — cards de resultado: corrigir exibição de `rating` (verificar model, parsing da resposta e widget de estrelas; usar `0.0` como fallback se campo vier nulo)
- [ ] Tela **Perfil** (User) — aplicar `.toTitleCase()` nos campos de nome exibidos
- [ ] Tela **Perfil** (Hotel) — aplicar `.toTitleCase()` nos campos de nome exibidos
- [ ] Tela **Perfil** (Admin) — aplicar `.toTitleCase()` nos campos de nome exibidos
- [ ] Seção **Legal** (User, Hotel, Admin) — substituir textos placeholder por conteúdo real quando disponibilizado pelo time de produto *(bloqueado até receber os textos)*
- [ ] Tela **Clientes** (Admin) — corrigir carregamento de `profileImageUrl`; adicionar fallback `CircleAvatar` com inicial do nome quando URL for nula ou inválida

---

### 10. Bugs visuais — Agendamentos e Criação de Quarto [PENDENTE]

- [ ] `lib/features/bookings/presentation/pages/agendamentos_page.dart` — filtros horizontais: envolver `SingleChildScrollView` com `ShaderMask` + `LinearGradient` nas bordas (ver spec seção E)
- [ ] `lib/features/bookings/presentation/pages/agendamentos_page.dart` — calendário: passar lista de datas com agendamentos existentes para o widget de calendário; implementar colorização dos dias com agendamento
- [ ] `lib/features/rooms/presentation/pages/add_room_page.dart` — extrair grid de comodidades para widget filho `AmenitiesSelector` (`ConsumerStatefulWidget`) com `onChanged(Set<int>)`, eliminando o rebuild global ao clicar em comodidade (ver spec seção F)

---

## Validação [PENDENTE]

- [ ] Alternar dispositivo/emulador para **dark mode** e navegar por todas as telas corrigidas — verificar que nenhuma cor fixa (branco, cinza `#D9D9D9`, preto) aparece como background ou texto principal
- [ ] Alternar para **light mode** e conferir que as mesmas telas continuam com visual correto (sem regressões)
- [ ] **Headers**: abrir cada tela migrada e confirmar — ícone de voltar `arrow_back_ios_new` 24px, notificação `notifications_none` 24px, título 20px w700, border radius 27
- [ ] **Logo**: em telas com header de fundo `AppColors.primary`, confirmar que `logoDark.svg` é exibido; em telas com fundo de tema variável, confirmar troca dinâmica dark/light
- [ ] **Scaffolds**: nas 5 telas corrigidas (checkout, public_ticket, reservation_success, whatsapp_payment, chat), confirmar que o fundo acompanha o tema
- [ ] **Cores de status**: em checkout e tickets, confirmar que ícone verde (sucesso) e vermelho (erro) são legíveis em dark mode
- [ ] **Toast "link copiado"** (tela Quarto): copiar link e verificar que o snackbar aparece com fundo `inverseSurface` em ambos os modos
- [ ] **Formulário Hotel** (criação de conta): confirmar que todos os campos têm ícones e que Termos e Condições abre como bottom sheet
- [ ] **Ícone de favoritar** (tela Quarto): tocar no ícone e confirmar feedback visual (cor ou preenchimento muda)
- [ ] **Botão "Finalizar Reserva"**: rolar a tela de Checkout até o fim — botão deve ser o último elemento
- [ ] **Feedback pós-pagamento**: completar o fluxo de seleção de pagamento e confirmar que o modal/Bottom Sheet de "aguardando confirmação" é exibido
- [ ] **Rating nos cards** (Search): buscar hotéis e confirmar que as estrelas/notas aparecem; verificar que `0.0` é exibido de forma neutra quando não há dados
- [ ] **Title Case** (Perfis): acessar perfis User, Hotel e Admin e confirmar que os nomes estão em Title Case
- [ ] **Fotos de perfil** (Admin > Clientes): abrir listagem e confirmar que as imagens carregam; remover conexão de rede e confirmar que o avatar padrão aparece como fallback
- [ ] **Filtros de Agendamentos**: com mais filtros do que a largura da tela comporta, confirmar que o gradiente de borda indica scrollability
- [ ] **Calendário de Agendamentos**: verificar que dias com agendamento têm cor de destaque diferente dos demais
- [ ] **Comodidades (Criação de Quarto)**: selecionar e desselecionar comodidades rapidamente — confirmar que não há flickering ou perda de posição de scroll no formulário
- [ ] `flutter analyze` — zero warnings novos introduzidos nesta branch
