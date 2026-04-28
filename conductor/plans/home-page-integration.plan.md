# Plan — Home Page Integration

> Derivado de: conductor/specs/home-page-integration.spec.md
> Status geral: [PENDENTE]

---

## Convenção de Código

> Aplicar em todos os arquivos criados ou modificados nesta feature.

- Adicionar comentário `// [descrição resumida]` imediatamente acima de cada função nova e de cada trecho de lógica crítica (ex: lógica de sorteio, fallback, condicionais de estado)
- Formato: uma linha, começando com `//`, sem ponto final
- Objetivo: facilitar identificação de conflitos em merges e revisão de código

## Segurança & Boas Práticas

> Aplicar em todos os arquivos criados ou modificados nesta feature.

**Backend:**
- [ ] Nunca expor `schema_name`, `hotel_id` interno ou dados de tenant diretamente na response — mapear para o shape público `RecommendedRoom`
- [ ] Sanitizar e escapar wildcards no parâmetro `q` antes de qualquer query ILIKE (padrão já adotado em `searchRoom.service.ts`)
- [ ] Limitar o resultado do endpoint a no máximo 5 itens no nível do service — não depender apenas do cliente
- [ ] Tratar timeout por tenant no fan-out cross-tenant — um tenant lento não deve derrubar a resposta inteira
- [ ] Logar erros com contexto estruturado (`[recommendedRooms]`, tenant, tempo) — nunca expor stack trace na response HTTP
- [ ] Seed deve rodar apenas em ambiente de desenvolvimento — adicionar guard `if (process.env.NODE_ENV !== 'production')`

**Flutter:**
- [ ] Nunca exibir mensagens de erro internas da API diretamente ao usuário — usar mensagem genérica amigável
- [ ] Validar que `roomId` recebido da API é não-nulo antes de passar para a rota `room_details`
- [ ] Não armazenar dados de recomendação em cache persistente — a variedade do sorteio depende de sempre buscar da API

---

## Setup & Infraestrutura [PENDENTE]

- [ ] **Criar** `src/database/seeds/seed.recommendedRooms.ts`

  Seed com 13 quartos distribuídos para cobrir os 3 cenários de recomendação:

  | Bloco | Qtd | Nota média | Comportamento esperado |
  |-------|-----|------------|------------------------|
  | Bloco A | 3 | 4.9 | Garantidos no topo |
  | Bloco B | 5 | 4.7 | Sorteio — 2 slots preenchidos aleatoriamente |
  | Bloco C | 3 | 3.5 | Não deve aparecer nas recomendações |
  | Sem avaliação | 2 | — | Usados apenas no fallback aleatório |

  Cada quarto deve conter: `nome`, `valor_diaria`, `categoria`, `comodidades` e avaliações vinculadas.
  Comentar o topo do arquivo identificando cada bloco de cenário.

---

## Backend [PENDENTE]

### 1. Service de Recomendação [PENDENTE]

- [ ] **Criar** `src/services/recommendedRooms.service.ts`
  - [ ] // Função principal: orquestra a lógica de recomendação e retorna 5 quartos
        `getRecommendedRooms(): Promise<RecommendedRoom[]>`
  - [ ] // Busca cross-tenant: coleta todos os quartos com suas médias de avaliação
        `fetchRoomsWithRatings(): Promise<RawRoom[]>`
  - [ ] // Agrupa quartos por bloco de nota DESC para separar empates
        `groupByRatingBlocks(rooms: RawRoom[]): RatingBlock[]`
  - [ ] // Sorteio: embaralha e retorna N itens aleatórios de um array
        `shufflePick<T>(arr: T[], n: number): T[]`
  - [ ] // Fallback: retorna 5 quartos aleatórios quando não há nenhuma avaliação
        `getRandomFallback(rooms: RawRoom[]): RecommendedRoom[]`
  - [ ] // Enriquecimento: monta o shape final RecommendedRoom com imagem_url e comodidades
        `enrichRoom(room: RawRoom, hotel: HotelMatch): RecommendedRoom`

### 2. Controller [PENDENTE]

- [ ] **Criar** `src/controllers/recommendedRooms.controller.ts`
  - [ ] // Handler HTTP: recebe GET /quartos/recomendados e delega ao service
        `handleGetRecommendedRooms(req, res)`
  - [ ] Tratar erro 500 com log estruturado (mesmo padrão de `searchRoom.controller.ts`)

### 3. Rota [PENDENTE]

- [ ] **Modificar** `src/routes/quarto.routes.ts`
  - [ ] Registrar `GET /recomendados` apontando para `handleGetRecommendedRooms`
  - [ ] // Rota pública — sem middleware de autenticação

### 4. Ajustes no `/quartos/busca` — EXT-2 [PENDENTE]

- [ ] **Modificar** `src/services/searchRoom.service.ts`
  - [ ] // Extensão do fan-out: filtro por numero e descricao do quarto nos tenants
        Adicionar `numero ILIKE $1 OR descricao ILIKE $1` no query do fan-out
  - [ ] // Extensão do fan-out: filtro por nome da categoria do quarto
        Adicionar JOIN com `categoria_quarto` e filtro `cq.nome ILIKE $1`
- [ ] **Verificar** `src/controllers/searchRoom.controller.ts` — ajustar se necessário para novos params

---

## Frontend [PENDENTE]

### 1. State [PENDENTE]

- [ ] **Criar** `lib/features/home/presentation/notifiers/home_state.dart`
  - [ ] // Estado imutável da home: lista de quartos recomendados, flag de loading e flag de erro
        Definir `HomeState` com `rooms: List<Room>`, `isLoading: bool`, `hasError: bool`

### 2. Notifier [PENDENTE]

- [ ] **Criar** `lib/features/home/presentation/notifiers/home_notifier.dart`
  - [ ] // Notifier principal: gerencia ciclo de vida das recomendações via AsyncNotifier
        `HomeNotifier extends AsyncNotifier<HomeState>`
  - [ ] // Carregamento: chama GET /quartos/recomendados e atualiza o estado
        Implementar `loadRecommended()`
  - [ ] // Tratamento de erro: captura exceções e seta hasError sem propagar para a UI
        Envolver chamada em try/catch com estado de erro
  - [ ] Registrar `homeNotifierProvider`

### 3. Shimmer [PENDENTE]

- [ ] **Criar** `lib/features/home/presentation/widgets/home_shimmer.dart`
  - [ ] // Placeholder animado: lista horizontal de cards shimmer enquanto os dados carregam
        Criar `HomeShimmer` usando o pacote `shimmer`
  - [ ] Dimensões e layout compatíveis com o `RoomCard` existente

### 4. Home Page [PENDENTE]

- [ ] **Modificar** `lib/features/home/presentation/pages/home_page.dart`

  **4.1 — Barra de busca**
  - [ ] // Toque no campo: navega para search_page com foco no campo de destino
        Envolver campo em `GestureDetector` com `onTap` chamando `context.push('/search')`
  - [ ] // Ícone de filtro: abre dropdown de comodidades sem sair da home
        Adicionar `IconButton` no final da barra que exibe `DropdownMenu` com lista de comodidades

  **4.2 — Cards de recomendação**
  - [ ] // Gatilho de carregamento: dispara loadRecommended ao montar o slide 2
        Chamar `loadRecommended()` em `initState` ou via `ref.listen` na montagem
  - [ ] // Substituição da lista hardcoded: observa homeNotifierProvider e renderiza dados reais
        Substituir lista mockada por `Consumer` lendo `homeNotifierProvider`
  - [ ] // Estado de loading: exibe HomeShimmer enquanto isLoading for true
        Condicionar renderização entre `HomeShimmer` e lista real
  - [ ] // Estado de erro: mensagem discreta sem bloquear a tela
        Tratar `hasError` com `SnackBar` ou `Text` não-intrusivo
  - [ ] // Estado vazio: fallback visual caso rooms esteja vazio
        Condicionar renderização para lista vazia
  - [ ] Garantir que `RoomCard` recebe `roomId` real para navegação correta para `room_details`

---

## Validação [PENDENTE]

- [ ] Rodar seed e confirmar no banco os 13 quartos inseridos nos cenários corretos
- [ ] **Cenário de empate:** chamar `GET /api/quartos/recomendados` 3 vezes seguidas e confirmar:
  - Os 3 quartos do Bloco A (nota 4.9) aparecem **sempre**
  - Os 2 slots restantes **variam** entre os 5 quartos do Bloco B (nota 4.7)
- [ ] **Cenário de fallback:** remover todas as avaliações e confirmar que 5 quartos aleatórios são retornados
- [ ] **Loading:** abrir slide 2 e verificar shimmer durante o carregamento
- [ ] **Dados reais:** confirmar que os 5 cards exibem nome, foto, nota e comodidades da API
- [ ] **Busca — campo:** tocar no campo de busca e confirmar navegação para `search_page` com foco no destino
- [ ] **Busca — filtro:** tocar no ícone de filtro e confirmar que o dropdown abre sem navegar
- [ ] **Navegação do card:** tocar em um card e confirmar navegação para `room_details` com `roomId` correto
- [ ] **Erro de API:** desligar o backend e confirmar mensagem discreta sem travar a tela
- [ ] `flutter analyze lib/` sem erros

---

## Regra de Atualização de Status

Ao marcar tasks como concluídas, atualizar o status da seção seguindo:
- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualizar o **Status geral** no topo para `[CONCLUÍDO]`
e sincronizar com `conductor/plan.md`:
- Localizar bloco correspondente à feature **Home Page Integration**
- Marcar a task como `[x]`
