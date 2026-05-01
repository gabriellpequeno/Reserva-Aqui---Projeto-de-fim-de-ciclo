# Plan — edit-room-page

> Derivado de: conductor/specs/edit-room-page.spec.md
> Status geral: [EM ANDAMENTO]

**Dependências:** Requer P0 (dioProvider), P2-A (login host com JWT), P4-E (my_rooms_page concluída), P5-A (CatalogoItemModel existente em `lib/features/rooms/domain/models/catalogo_item.dart`).
**Bloqueia:** — (folha)

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Confirmar que todos os endpoints necessários já existem no backend (quartos, categorias, catalogo, uploads)
- [x] Confirmar que `CatalogoItemModel` já foi criado por P5-A em `lib/features/rooms/domain/models/catalogo_item.dart`
- [x] Confirmar que `image_picker` está no `pubspec.yaml` (já usado em `add_room_page.dart`)
- [x] Confirmar que `dio` suporta `FormData` + `MultipartFile` (já usado em `add_room_notifier.dart`)

---

## Backend [CONCLUÍDO]

> Todos os endpoints necessários já existem e estão funcionais. Nenhuma alteração de backend é necessária.

- [x] `GET /hotel/me` — existente
- [x] `GET /hotel/quartos/:id` — existente
- [x] `GET /:hotel_id/categorias/:id` — existente
- [x] `GET /uploads/hotels/:hotel_id/rooms/:quarto_id` — existente
- [x] `GET /:hotel_id/catalogo` — existente
- [x] `PATCH /hotel/categorias/:id` — existente
- [x] `POST /hotel/categorias/:id/itens` — existente
- [x] `DELETE /hotel/categorias/:id/itens/:catalogo_id` — existente
- [x] `PATCH /hotel/quartos/:id` — existente
- [x] `DELETE /uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id` — existente
- [x] `POST /uploads/hotels/:hotel_id/rooms/:quarto_id` — existente

---

## Frontend [CONCLUÍDO]

### Modelos de Domínio

- [x] Criar `FotoExistente` em `lib/features/rooms/domain/models/foto_existente.dart`
  - Campos: `id: String`, `url: String`
  - `factory FotoExistente.fromJson(Map<String, dynamic> json)`

### State (Riverpod)

- [x] Criar `EditRoomState` em `lib/features/rooms/presentation/notifiers/edit_room_state.dart`
  - Campos: `loading: bool`, `loadError: String?`, `quartoId: String?`, `categoriaId: String?`, `hotelId: String?`, `nome: String?`, `descricao: String?`, `valorDiaria: double?`, `capacidade: int?`, `disponivel: bool`, `catalogoItens: List<CatalogoItemModel>`, `comodidadesAtuais: Set<int>`, `fotosExistentes: List<FotoExistente>`, `saving: bool`, `saveStep: String?`, `saveError: String?`, `saveSuccess: bool`
  - Método `copyWith` e instância inicial com `loading: false`

- [x] Criar `EditRoomNotifier` em `lib/features/rooms/presentation/notifiers/edit_room_notifier.dart`
  - Método `load(String roomId)`: busca hotel_id → carrega quarto → em paralelo (categoria + fotos + catálogo) → popula state com todos os campos
  - Método `save(...)`: PATCH categoria → diff comodidades (POST/DELETE) → PATCH quarto → DELETE fotos → POST fotos
  - Métodos auxiliares: `clearSaveError()`, `_fetchHotelId`, `_loadCategoria`, `_loadFotos`, `_loadCatalogo`, `_parseDouble`, `_mensagemErro`
  - `final editRoomNotifierProvider = NotifierProvider<EditRoomNotifier, EditRoomState>(EditRoomNotifier.new)`

### Página (refatoração de `edit_room_page.dart`)

- [x] Converter `EditRoomPage` de `StatefulWidget` para `ConsumerStatefulWidget`
- [x] Remover campos "Camas" e "Banheiros" sem suporte na API
- [x] Adicionar estado local: `Set<int> _selectedComodidadeIds`, `final Set<String> _fotosParaRemover`, `List<XFile> _fotosNovas`
- [x] Implementar `initState` que dispara `load(widget.roomId)` via `Future.microtask`
- [x] Implementar `_tryPopulateForm` — popula controllers uma única vez quando `state.nome != null && !loading`; chamado no `build` e no `ref.listen`
- [x] Exibir `CircularProgressIndicator` enquanto `state.loading`
- [x] Exibir estado de erro com botão de voltar quando `state.loadError != null`
- [x] Seção de comodidades com `FilterChip` agrupados por categoria, spinner durante carregamento, mensagem se lista vazia
- [x] Seção de fotos: `Image.network` para existentes (com botão "X" → marca em `_fotosParaRemover`), `Image.file/network` para novas (com "X"), botão "Adicionar" via `image_picker`, contador de remoções pendentes
- [x] `LinearProgressIndicator` + `Text(state.saveStep)` durante `state.saving`
- [x] Botão "Salvar Alterações" bloqueado durante save
- [x] `ref.listen`: `saveSuccess` → reload `MyRoomsNotifier` → `context.pop()`; `saveError` → SnackBar → `clearSaveError()`
- [x] `_submit()` invoca `notifier.save(...)` com todos os parâmetros do estado local

---

## Validação [PENDENTE]

- [ ] **Carregamento:** navegar para `/edit_room/:roomId` → campos populados com dados reais do quarto/categoria
- [ ] **Comodidades carregadas:** comodidades atuais da categoria aparecem como chips selecionados; restantes do catálogo como não selecionados
- [ ] **Fotos existentes:** thumbnails das fotos do quarto exibidos com botão "X"
- [ ] **Edição de categoria:** alterar nome, preço, capacidade → salvar → PATCH categoria executado com sucesso no backend
- [ ] **Toggle de status:** desmarcar "Status do Quarto" → salvar → `disponivel: false` atualizado no backend
- [ ] **Adicionar comodidade:** selecionar chip não selecionado → salvar → POST item executado
- [ ] **Remover comodidade:** desmarcar chip selecionado → salvar → DELETE item executado
- [ ] **Remover foto existente:** tocar "X" → opacidade reduzida → salvar → DELETE foto executado
- [ ] **Adicionar foto nova:** selecionar da galeria → thumbnail exibido → salvar → POST foto executado
- [ ] **Progresso visível:** `LinearProgressIndicator` + texto de etapa aparecem durante o save
- [ ] **Erro no save:** simular falha num PATCH → SnackBar descritivo → formulário permanece aberto
- [ ] **Quarto não encontrado:** navegar com `roomId` inválido → estado de erro com botão de voltar; sem crash
- [ ] **Navegação pós-sucesso:** ao fechar, `my_rooms_page` exibe os dados atualizados sem navegação manual
