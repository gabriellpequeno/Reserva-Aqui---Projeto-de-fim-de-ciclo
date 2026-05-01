# Plan — add-room-page

> Derivado de: conductor/specs/add-room-page.spec.md
> Status geral: [EM ANDAMENTO]

**Dependências:** Requer P0 (dioProvider), P2-A (login host com JWT) e P4-E (my_rooms_page concluída — esta tela é acessada pelo FAB dela).
**Bloqueia:** — (folha)

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Confirmar que `dio` no projeto já suporta `FormData` + `MultipartFile` para upload multipart (verificar em `Frontend/pubspec.yaml` — versão `^5.x` é suficiente)
- [x] Confirmar que `image_picker` está nos `pubspec.yaml` e nas permissões de manifesto Android/iOS (já usado na página atual — verificar se está declarado)

---

## Backend [CONCLUÍDO]

> Todos os endpoints necessários já existem e estão funcionais. Nenhuma alteração de backend é necessária para esta feature.

- [x] `GET /:hotel_id/catalogo` — existente (`catalogo.routes.ts`)
- [x] `GET /hotel/me` — existente (`anfitriao.routes.ts`)
- [x] `POST /hotel/categorias` — existente (`categoriaQuarto.routes.ts`)
- [x] `POST /hotel/categorias/:id/itens` — existente (`categoriaQuarto.routes.ts`)
- [x] `POST /hotel/quartos` — existente (`quarto.routes.ts`)
- [x] `POST /uploads/hotels/:hotel_id/rooms/:quarto_id` — existente (`upload.routes.ts`)

---

## Frontend [CONCLUÍDO]

### Modelos de Domínio

- [x] Criar `CatalogoItemModel` em `lib/features/rooms/domain/models/catalogo_item.dart`
  - Campos: `id: int`, `nome: String`, `categoria: String`
  - `factory CatalogoItemModel.fromJson(Map<String, dynamic> json)`

### State (Riverpod)

- [x] Criar `AddRoomState` em `lib/features/rooms/presentation/notifiers/add_room_state.dart`
  - Campos: `catalogoItens: List<CatalogoItemModel>`, `loadingCatalogo: bool`, `submitting: bool`, `submitStep: String?`, `error: String?`, `success: bool`
  - Método `copyWith` e constante `AddRoomState()` inicial

- [x] Criar `AddRoomNotifier` em `lib/features/rooms/presentation/notifiers/add_room_notifier.dart`
  - Método `loadCatalogo()`: busca `hotel_id` via `GET /hotel/me`, depois `GET /:hotel_id/catalogo`; popula `state.catalogoItens`; define `error` se `hotel_id` for nulo
  - Método `submit({nome, valorDiaria, capacidade, comodidadeIds, numeroUnidades, fotos})`:
    1. Define `submitting: true`, `submitStep: 'Criando categoria...'`
    2. `POST /hotel/categorias` → `categoriaId`
    3. Para cada `id` em `comodidadeIds`: `POST /hotel/categorias/$categoriaId/itens` com `{catalogo_id: id, quantidade: 1}`
    4. Atualiza `submitStep: 'Criando quartos...'`; para `i` em `range(numeroUnidades)`: `POST /hotel/quartos` com `{numero: (i+1).toString().padLeft(3,'0'), categoria_quarto_id: categoriaId}` → coleta `primeiroQuartoId` da primeira iteração
    5. Se `fotos` não vazio: atualiza `submitStep: 'Enviando fotos...'`; para cada foto: `POST /uploads/hotels/$hotelId/rooms/$primeiroQuartoId` via `FormData` + `MultipartFile.fromBytes`
    6. Define `submitting: false`, `success: true`; em caso de erro em qualquer etapa, define `submitting: false`, `error: mensagem`
  - `final addRoomNotifierProvider = NotifierProvider<AddRoomNotifier, AddRoomState>(AddRoomNotifier.new)`

### Página (refatoração de `add_room_page.dart`)

- [x] Converter `AddRoomPage` de `StatefulWidget` para `ConsumerStatefulWidget`

- [x] Substituir campo "Comodidades" (String dropdown → multi-select):
  - State local: `final Set<int> _selectedAmenityIds = {}`
  - Consumir `state.catalogoItens` para renderizar chips selecionáveis (`FilterChip`) agrupados ou em wrap
  - Exibir `CircularProgressIndicator` enquanto `loadingCatalogo: true`
  - Exibir texto "Sem comodidades cadastradas" se lista vazia

- [x] Substituir campo "Valor da Diária" (String dropdown → campo numérico):
  - Trocar `_selectedPrice` por `TextEditingController _priceController` + `TextInputType.numberWithOptions(decimal: true)`
  - Validar que `double.tryParse(_priceController.text) != null && valor > 0`

- [x] Substituir campo "Capacidade" (String dropdown → stepper numérico):
  - `int _capacity = 2` (já há `_buildNumberInput` na página — reutilizado)
  - Removida a lista `capacities` e o dropdown original

- [x] Disparar `ref.read(addRoomNotifierProvider.notifier).loadCatalogo()` no `initState`

- [x] Exibir `LinearProgressIndicator` + texto `state.submitStep` durante `state.submitting: true`

- [x] Bloquear botão "Criar quarto" (exibe `CircularProgressIndicator`) enquanto `state.submitting: true`

- [x] Listener de estado no `build` (via `ref.listen`):
  - Quando `state.success: true` → chamar `ref.read(myRoomsNotifierProvider.notifier).load()` e então `context.pop()`
  - Quando `state.error != null` → exibir `SnackBar` com a mensagem de erro e limpar via `clearError()`

- [x] Ao tocar em "Criar quarto", invocar `notifier.submit(nome: ..., valorDiaria: ..., capacidade: ..., comodidadeIds: _selectedAmenityIds, numeroUnidades: _numberOfRooms, fotos: _selectedImages)`

---

## Validação [PENDENTE]

- [ ] **Catálogo carregado:** abrir a tela → chips de comodidades do catálogo do hotel aparecem
- [ ] **Catálogo vazio:** hotel sem catálogo → mensagem "Sem comodidades cadastradas" visível; formulário pode ser submetido sem comodidades
- [ ] **Validação de formulário:** tocar em "Criar quarto" com nome/valor/foto vazios → validação inline impede submit
- [ ] **Valor decimal:** campo de valor aceita "249.90" e é enviado corretamente como `double` 
- [ ] **Happy path completo:** preencher todos os campos + selecionar comodidades + adicionar fotos → submit → categoria + quartos + fotos criados no backend → `my_rooms_page` exibe novo card
- [ ] **Progresso visível:** indicator + texto de etapa aparecem durante o submit
- [ ] **Erro numa etapa:** simular falha no `POST /hotel/quartos` → SnackBar descritivo → formulário permanece aberto
- [ ] **Múltiplas unidades:** `_numberOfRooms = 3` → 3 quartos criados no backend com números "001", "002", "003"
- [ ] **Navegação pós-sucesso:** ao fechar, `my_rooms_page` carrega e exibe a nova categoria sem navegação manual
