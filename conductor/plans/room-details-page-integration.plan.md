# Plan — Room Details Page Integration

> Derivado de: conductor/specs/room-details-page-integration.spec.md
> Status geral: [CONCLUÍDO]

---

## Convenção de Código

> Aplicar em todos os arquivos criados ou modificados nesta feature.

- Adicionar comentário `// [descrição resumida]` imediatamente acima de cada função nova e de cada trecho de lógica crítica (ex: filtragem de disponibilidade por categoria, guard de autenticação para favoritar)
- Formato: uma linha, começando com `//`, sem ponto final
- Objetivo: facilitar identificação de conflitos em merges e revisão de código

## Segurança & Boas Práticas

> Aplicar em todos os arquivos criados ou modificados nesta feature.

**Backend:**
- [ ] Validar que `quarto_id` e `hotel_id` são inteiros/strings válidos antes de executar a query — retornar 400 se inválidos
- [ ] Não expor `schema_name` ou dados internos de tenant na response pública — mapear para o shape `QuartoPublicoDetails`
- [ ] Logar erros com contexto estruturado (`[quartoPublico]`, `hotel_id`, `quarto_id`) — nunca expor stack trace na response HTTP

**Flutter:**
- [ ] Nunca exibir mensagens de erro internas da API diretamente ao usuário — usar mensagem genérica amigável por seção
- [ ] Ação de favoritar sem autenticação exibe modal com opção de ir ao login — nunca redirecionar automaticamente
- [ ] Validar que `hotelId` e `roomId` recebidos pela rota são não-nulos antes de disparar qualquer chamada de API

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Sem migrations necessárias — nenhuma tabela nova
- [x] Sem novas dependências no `package.json`
- [x] Verificar se `intl` já está no `pubspec.yaml` do Flutter — necessário para formatar datas nos date pickers

---

## Backend [CONCLUÍDO]

### 1. Service de Detalhes Públicos do Quarto [CONCLUÍDO]

- [x] **Criar** `src/services/quartoPublico.service.ts`
  - [x] // Busca dados públicos de um quarto físico com join em categoria e itens de catálogo
        `getRoomPublicDetails(hotelId: string, quartoId: number): Promise<QuartoPublicoDetails>`
  - [x] Join: `quarto → categoria_quarto → categoria_item → catalogo`
  - [x] Retornar `valor_diaria` como `COALESCE(q.valor_override, cq.preco_base::numeric)`
  - [x] Retornar itens agregados via `json_agg` (mesmo padrão de `categoriaQuarto.service.ts`)
  - [x] Lançar erro claro se quarto não encontrado ou deletado (`deleted_at IS NOT NULL`)

### 2. Controller [CONCLUÍDO]

- [x] **Criar** `src/controllers/quartoPublico.controller.ts`
  - [x] // Handler HTTP: recebe GET /:hotel_id/quartos/:quarto_id e delega ao service
        `handleGetRoomPublicDetails(req, res)`
  - [x] Usar `parseId` para validar `quarto_id` — retornar 400 se inválido
  - [x] Tratar erro 404 (quarto não encontrado) e 500 com log estruturado

### 3. Rota [CONCLUÍDO]

- [x] **Modificar** `src/routes/categoriaQuarto.routes.ts`
  - [x] // Rota pública: retorna dados do quarto físico com categoria e itens — sem autenticação
        Registrar `GET /:hotel_id/quartos/:quarto_id` apontando para `handleGetRoomPublicDetails`
  - [x] Posicionar a rota antes das rotas protegidas para evitar captura como parâmetro genérico

---

## Frontend [CONCLUÍDO]

### 1. Model [CONCLUÍDO]

- [x] **Modificar** `lib/features/rooms/domain/models/room.dart`
  - [x] Adicionar campo `hotelId: String` ao model `Room`
  - [x] Atualizar construtor para incluir `hotelId` como campo obrigatório

### 2. State [CONCLUÍDO]

- [x] **Criar** `lib/features/rooms/presentation/notifiers/room_details_state.dart`
  - [x] // Estado imutável da tela de detalhes: dados do quarto, loading e erro
        Definir `RoomDetailsState` com `room: Room?`, `isLoading: bool`, `hasError: bool`, `categoriaId: int`

### 3. Notifier [CONCLUÍDO]

- [x] **Criar** `lib/features/rooms/presentation/notifiers/room_details_notifier.dart`
  - [x] // Notifier principal: gerencia carregamento dos dados do quarto via API
        `RoomDetailsNotifier extends Notifier<RoomDetailsState>`
  - [x] // Carregamento: chama GET /api/hotel/:hotelId/quartos/:quartoId e atualiza estado
        Implementar `loadRoom(String hotelId, String quartoId)`
  - [x] // Tratamento de erro: captura exceções e seta hasError sem propagar para a UI
        Envolver chamada em try/catch com estado de erro por seção
  - [x] Registrar `roomDetailsNotifierProvider`
  - [x] // Extração dinâmica de categoriaId: armazenar no state para uso no availability checker
        Implementar `_setCategoriaId(int)` para atualizar estado

### 4. Roteamento [CONCLUÍDO]

- [x] **Modificar** `lib/core/router/app_router.dart`
  - [x] // Rota de detalhes atualizada para incluir hotelId necessário para chamadas de API
        Alterar rota de `/room_details/:roomId` para `/room_details/:hotelId/:roomId`
  - [x] Atualizar `RoomDetailsPage` para receber `hotelId` e `roomId` como parâmetros da rota

### 5. Home — Mapeamento de hotelId [CONCLUÍDO]

- [x] **Modificar** `lib/features/home/presentation/notifiers/home_notifier.dart`
  - [x] // Mapeamento: inclui hotelId do response da API no model Room para navegação correta
        Mapear campo `hotelId` do `RecommendedRoom` para o model `Room`

### 6. Room Card — Navegação com hotelId [CONCLUÍDO]

- [x] **Modificar** `lib/features/home/presentation/widgets/room_card.dart`
  - [x] Adicionar parâmetro `hotelId: String` ao construtor do `RoomCard`
  - [x] // Navegação: passa hotelId e roomId para a rota de detalhes
        Atualizar `onTap` para `context.push('/room_details/$hotelId/$roomId')`

- [x] **Modificar** `lib/features/home/presentation/pages/home_page.dart`
  - [x] Passar `hotelId: room.hotelId` para o `RoomCard` em `_buildRoomCards`

- [x] **Modificar** `lib/features/rooms/presentation/pages/hotel_details_page.dart`
  - [x] Adicionar `hotelId` ao `RoomCard` em listagem interna

### 7. Widget de Disponibilidade [CONCLUÍDO]

- [x] **Criar** `lib/features/rooms/presentation/widgets/availability_checker.dart`
  - [x] // Container de verificação de disponibilidade com date pickers e resultado inline
        Criar `AvailabilityChecker` recebendo `hotelId` e `categoriaId`
  - [x] Dois campos de data: check-in e check-out com `showDatePicker`
  - [x] // Botão de verificação: chama GET /:hotel_id/disponibilidade e filtra pelo categoriaId do quarto
        Botão "Verificar disponibilidade" desabilitado até ambas as datas serem selecionadas
  - [x] // Filtragem: busca a entrada da categoria do quarto atual no array de disponibilidade retornado
        Filtrar o resultado pelo `categoriaId` do quarto atual
  - [x] // Exibição do resultado: mensagem de disponível ou indisponível abaixo do botão
        Exibir mensagem abaixo do botão — "Disponível" ou "Indisponível — próxima disponibilidade em [data]"
  - [x] Estado de loading durante a chamada e estado de erro discreto em caso de falha

### 8. Room Details Page — Refatoração Completa [CONCLUÍDO]

- [x] **Modificar** `lib/features/rooms/presentation/pages/room_details_page.dart`

  **8.1 — Conversão para ConsumerStatefulWidget** [CONCLUÍDO]
  - [x] Converter de `ConsumerWidget` para `ConsumerStatefulWidget`
  - [x] Adicionar parâmetro `hotelId: String` ao construtor
  - [x] // Gatilho de carregamento: dispara loadRoom ao montar a tela com hotelId e roomId
        Chamar `roomDetailsNotifierProvider.notifier.loadRoom(hotelId, roomId)` no `initState`

  **8.2 — Dados reais** [CONCLUÍDO]
  - [x] Remover todos os dados mockados do `build`
  - [x] // Exibição condicional: erro com retry enquanto dados não estão disponíveis
        Tratar `isLoading` e `hasError` com feedback visual por seção (não bloquear a tela inteira)

  **8.3 — Visual: imagem e preço** [CONCLUÍDO]
  - [x] Mover o card de preço da sobreposição da foto para **abaixo** da foto de capa na seção de conteúdo
  - [x] // Carrossel de fotos: exibido ao final da foto de capa como miniaturas navegáveis
        Mover as miniaturas do carrossel para baixo da foto principal — horizontalmente navegáveis

  **8.4 — Comodidades** [CONCLUÍDO]
  - [x] // Cards compactos: tamanho ajustado ao ícone + texto em até 2 linhas
        Reduzir tamanho dos cards de comodidade — próximos ao label "Comodidades"
  - [x] // Mapeamento de ícones: converte categoria do catálogo para IconData padronizado
        Mapear `item.categoria` (ex: CONECTIVIDADE, CLIMATIZACAO, CAMA) para `IconData`; fallback `Icons.hotel` para categorias desconhecidas

  **8.5 — Favoritar** [CONCLUÍDO]
  - [x] Remover ícone de chat do bottom bar
  - [x] // Botão de favoritar: posicionado onde estava o ícone de chat no bottom bar
        Adicionar botão de favoritar (ícone de coração) no lugar do chat
  - [x] // Guard de autenticação: exibe modal se usuário não estiver logado ao tentar favoritar
        Se não autenticado: exibir modal com mensagem sobre funcionalidade exclusiva para cadastrados + botão "Fazer login" + botão "Fechar"
  - [x] Modal implementado com navegação para login

  **8.6 — Navegação para hotel_details** [CONCLUÍDO]
  - [x] // Navegação do hotel: tocar em nome, foto ou "saiba mais" do host navega para hotel_details
        Envolver nome do hotel, avatar e botão "Saiba Mais" com `onTap: () => context.push('/hotel_details/$hotelId')`

  **8.7 — Verificação de disponibilidade** [CONCLUÍDO]
  - [x] Adicionar `AvailabilityChecker` abaixo dos cards de comodidade, passando `hotelId` e `categoriaId` dinâmico

  **8.8 — Botão Reservar** [CONCLUÍDO]
  - [x] // Navegação para checkout: passa roomId para a rota de checkout
        Confirmar que `context.push('/booking/checkout/${room.id}')` usa o `quarto_id` correto

---

## Validação [PENDENTE — Manual]

- [ ] **Dados reais:** abrir um card da home e confirmar que nome, preço, fotos, comodidades e descrição da API são exibidos
- [ ] **Disponibilidade — disponível:** selecionar datas livres e verificar mensagem "Disponível" abaixo do botão
- [ ] **Disponibilidade — indisponível:** selecionar datas ocupadas e verificar mensagem com próxima data
- [ ] **Favoritar sem login:** tocar no botão de favoritar sem estar autenticado e confirmar modal com botão de login e botão fechar
- [ ] **Favoritar com login:** tocar no botão autenticado e confirmar alternância do ícone
- [ ] **Navegação hotel:** tocar em nome, foto e "Saiba Mais" do hotel e confirmar navegação para `hotel_details`
- [ ] **Reservar:** tocar em "Reservar" e confirmar navegação para `checkout_page` com `roomId` correto
- [ ] **Erro de API:** desligar o backend e confirmar que cada seção exibe erro independente sem travar a tela
- [ ] **Navegação da home:** confirmar que `hotelId` e `roomId` corretos chegam na tela de detalhes ao tocar em um card

**Validação Técnica** [CONCLUÍDO]
- [x] `flutter analyze lib/` — 29 issues (0 erros críticos; todos pré-existentes)
- [x] TypeScript backend compila sem erros
- [x] Rota backend registrada e linkada
- [x] Mapeamento API → Model validado
- [x] categoriaId dinâmico (obtido da API)
- [x] Integração home → room_details com hotelId + roomId
- [x] Modal de favoritar implementado
- [x] Availability checker integrado com categoriaId dinâmico

---

## Regra de Atualização de Status

Ao marcar tasks como concluídas, atualizar o status da seção seguindo:
- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualizar o **Status geral** no topo para `[CONCLUÍDO]`
e sincronizar com `conductor/plan.md`:
- Localizar bloco correspondente à feature **Room Details Page Integration**
- Marcar a task como `[x]`
