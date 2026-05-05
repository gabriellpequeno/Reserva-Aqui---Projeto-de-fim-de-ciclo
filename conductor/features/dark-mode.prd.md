# PRD — Dark Mode

## Contexto
A infraestrutura de tema já existe no app: `ThemeNotifier` (Riverpod) persiste a preferência via `shared_preferences`, `MaterialApp.router` consome `themeMode` e a `SettingsPage` já expõe o toggle de Dark Mode (entregue em P3-E). Porém, a maioria das telas ainda usa cores hardcoded (`AppColors.backgroundLight`, `Colors.white`, `Color(0xFF...)`) e ignora `Theme.of(context)`, fazendo com que o tema escuro apareça quebrado visualmente em produção.

## Problema
Quando o usuário ativa o Dark Mode nas configurações, várias páginas permanecem com fundo claro, textos de baixo contraste e widgets visualmente inconsistentes. Isso inviabiliza o uso real do tema escuro e compromete a apresentação do MVP, onde Dark/Light mode é requisito obrigatório do PRD de produto.

## Público-alvo
Todos os usuários finais do app (guest, host e admin) que utilizam o Reserva Aqui em ambientes com pouca luz, têm preferência pessoal por interfaces escuras ou precisam do tema escuro por questões de acessibilidade e conforto visual.

## Requisitos Funcionais
1. Todas as páginas em `presentation/` devem consumir cores semânticas via `Theme.of(context).colorScheme.*` em vez de cores hardcoded
2. O `AppColors` (ou `ColorScheme` do `app_theme.dart`) deve expor tokens semânticos completos: `surface`, `onSurface`, `background`, `onBackground`, `cardBackground`, `divider`
3. O `ThemeData` escuro deve ter um `ColorScheme.dark` correto, garantindo contraste adequado entre fundo e texto
4. Os widgets compartilhados em `core/widgets/` devem seguir o mesmo padrão semântico (sem cores fixas)
5. O toggle de Dark Mode na `SettingsPage` deve continuar alternando o tema em tempo real para todas as telas corrigidas

## Requisitos Não-Funcionais
- [ ] Acessibilidade: contraste mínimo WCAG AA entre texto e fundo em ambos os temas
- [ ] Responsividade: funcionar em mobile (Android) e web (Chrome)
- [ ] Performance: troca de tema deve ser instantânea, sem re-render perceptível
- [ ] Consistência visual: ícones, placeholders e imagens não podem ter fundo branco visível no tema escuro

## Critérios de Aceitação
- Dado que o usuário ativou Dark Mode, quando navegar para Home, Hotel Details, Room Details, My Rooms, Notifications, Tickets, Search, Checkout, User/Host/Admin Profile, então cada página deve exibir fundo e textos no esquema escuro
- Dado que o tema escuro está ativo, quando visualizar qualquer widget compartilhado de `core/widgets/`, então ele deve respeitar o `ColorScheme` atual
- Dado que o usuário alterna o tema na Settings, quando a mudança acontece, então todas as telas refletem o novo tema sem precisar reiniciar o app
- Dado que o usuário reabre o app, quando ele já tinha escolhido Dark Mode, então a preferência deve persistir (comportamento já entregue em P3-E)
- Dado que um texto está sobre fundo escuro, quando exibido, então deve atender o contraste mínimo para leitura

## Fora de Escopo
- Criar um segundo sistema de tema — deve-se usar o `ThemeNotifier` existente
- Temas customizáveis além de claro e escuro (ex: alto contraste, temas sazonais)
- Sincronização da preferência de tema com o backend
- Detecção automática do tema do sistema operacional (seguir configuração do SO)
- Refatoração ou redesenho visual das páginas além da substituição de cores

## Arquivos Impactados

| Arquivo | O que muda |
|---------|-----------|
| `lib/core/theme/app_colors.dart` | Adicionar tokens semânticos faltantes |
| `lib/core/theme/app_theme.dart` | Garantir `darkTheme` com `ColorScheme.dark` completo |
| `lib/presentation/**/*_page.dart` | Substituir cores hardcoded por `Theme.of(context).colorScheme.*` |
| `lib/core/widgets/*` | Mesma substituição em widgets compartilhados |

Páginas prioritárias (em ordem de visibilidade para apresentação): `home_page`, `hotel_details_page`, `room_details_page`, `user_profile_page`, `host_profile_page`, `admin_profile_page`, `my_rooms_page`, `notifications_page`, `tickets_page`, `ticket_details_page`, `search_page`, `checkout_page`.

## Validação
- [ ] `flutter run -d chrome` com tema Dark ativo
- [ ] Emulador Android com tema Dark ativo
- [ ] Conferência manual de contraste em textos principais
- [ ] Conferência de ícones/placeholders sem fundo branco remanescente
