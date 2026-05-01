# Spec — add-room-page

## Referência
- **PRD:** conductor/features/add-room-page.prd.md

## Abordagem Técnica

Converter `AddRoomPage` de `StatefulWidget` para `ConsumerStatefulWidget` (Riverpod), criando `AddRoomNotifier` + `AddRoomState` seguindo o mesmo padrão de `MyRoomsNotifier`. Ao montar a tela, disparar `loadCatalogo()` que busca o `hotel_id` via `GET /hotel/me` e em seguida `GET /:hotel_id/catalogo`. O fluxo de submit é orquestrado inteiramente pelo notifier, expondo um estado de progresso granular (`submitStep`) consumido pela página para exibir feedback.

No formulário: `_selectedAmenities` evolui de `String?` dropdown → `Set<int>` de IDs do catálogo exibidos como chips filtráveis; `_selectedPrice` evolui de `String?` dropdown → `TextEditingController` numérico decimal; `_selectedCapacity` evolui de `String?` dropdown → `int` com stepper (mesmo widget `_buildNumberInput` já existente). O campo "Nº Quartos" (`_numberOfRooms`) sobrevive sem alteração — controla quantas unidades físicas serão criadas.

Upload de fotos: `dio.post` com `FormData` + `MultipartFile.fromBytes`, chamado sequencialmente para as fotos selecionadas, todas associadas ao `quarto_id` da **primeira** unidade criada. `MyRoomsNotifier._loadFotoCard` já percorre todos os `quartoIds` da categoria para encontrar a foto — associar ao primeiro quarto é suficiente.

## Componentes Afetados

### Backend
- Nenhum endpoint novo. Todos os endpoints necessários já existem e estão funcionais.

### Frontend
- **Novo:** `CatalogoItemModel` (`lib/features/rooms/domain/models/catalogo_item.dart`)
- **Novo:** `AddRoomState` (`lib/features/rooms/presentation/notifiers/add_room_state.dart`)
- **Novo:** `AddRoomNotifier` (`lib/features/rooms/presentation/notifiers/add_room_notifier.dart`)
- **Modificado:** `add_room_page.dart` — converter para `ConsumerStatefulWidget`, integrar com `addRoomNotifierProvider`, refatorar campos de amenities/preço/capacidade, exibir progresso de submit, navegar e recarregar `MyRoomsNotifier` ao sucesso

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| Notifier dedicado (`AddRoomNotifier`) | Fluxo de N chamadas encadeadas com estado de loading granular — separar da página facilita futura testabilidade |
| `hotel_id` buscado via `GET /hotel/me` no notifier | Mesmo padrão de `MyRoomsNotifier._fetchHotelId` — autossuficiente, sem dependência de provider externo |
| Fotos uploadadas apenas para o primeiro quarto criado | `MyRoomsNotifier._loadFotoCard` já percorre todos os `quartoIds` até achar uma foto; duplicar para cada unidade é desnecessário |
| `numero` do quarto gerado automaticamente | Gerar como `(baseIndex + i).toString().padLeft(3, '0')` (ex: "001", "002"); evita campo extra no formulário |
| Upload sequencial das fotos | `imageUpload.single('foto')` — API recebe uma foto por vez; sequencial evita race condition e reduz uso de memória |
| Comodidades multi-select como `Set<int>` de IDs | API espera `catalogo_id` inteiro; evita mapeamento nome→id na hora do submit; comparações O(1) |
| Recarregar `MyRoomsNotifier` ao fechar | A página anterior precisa refletir o novo quarto — chamar `load()` no notifier pai antes de fazer pop garante lista atualizada |

## Contratos de API

| Método | Rota | Body | Response | Status |
|--------|------|------|----------|--------|
| GET | `/hotel/me` | — | `{ data: { hotel_id: string, ... } }` | existente |
| GET | `/:hotel_id/catalogo` | — | `{ data: CatalogoItem[] }` | existente (público) |
| POST | `/hotel/categorias` | `{ nome, valor_diaria, capacidade_pessoas }` | `{ data: CategoriaQuartoSafe }` | existente |
| POST | `/hotel/categorias/:id/itens` | `{ catalogo_id, quantidade }` | `{ data: CategoriaItemSafe }` | existente |
| POST | `/hotel/quartos` | `{ numero, categoria_quarto_id }` | `{ data: Quarto }` | existente |
| POST | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | `FormData { foto: File }` | `{ fotos: [{ url }] }` | existente (multipart) |

**Nota:** Endpoints `hotel/*` exigem `hotelGuard` (JWT + `hotel_id` no contexto). O endpoint de catálogo é público mas identificado por `hotel_id`.

## Modelos de Dados

```
CatalogoItemModel {
  id: int
  nome: String
  categoria: String
}

AddRoomState {
  catalogoItens: List<CatalogoItemModel>   // comodidades disponíveis para seleção
  loadingCatalogo: bool
  submitting: bool
  submitStep: String?    // ex: "Criando categoria...", "Adicionando comodidades...", "Criando quartos...", "Enviando fotos..."
  error: String?
  success: bool
}
```

**Parâmetros do método `submit`:**
```
submit({
  required String nome,
  required double valorDiaria,
  required int capacidade,
  required Set<int> comodidadeIds,
  required int numeroUnidades,
  required List<XFile> fotos,
})
```

## Dependências

**Bibliotecas:**
- [x] `dio ^5.7.0` — cliente HTTP + `FormData`/`MultipartFile` para upload (já presente)
- [x] `flutter_riverpod ^3.3.1` — state management (já presente)
- [x] `image_picker` — seleção de imagens (já presente na página atual)
- [x] `go_router ^17.2.1` — navegação (já presente)

**Serviços externos:** nenhum.

**Outras features:**
- [x] P0 — `dioProvider` configurado com interceptor de autenticação
- [x] P2-A — login host (JWT válido no `dioProvider`)
- [x] P4-E — `my_rooms_page` que navega para esta tela via FAB (`/add_room`) e deve ser recarregada ao retornar

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Categoria criada mas criação de quartos falha → estado parcial no backend | Exibir erro com mensagem descritiva; sem rollback automático (aceito como marginal — host pode excluir via `my_rooms_page`) |
| Upload falha após quartos criados | Quartos existem sem foto; host pode usar `edit_room_page` futuramente para adicionar fotos; exibir aviso no SnackBar |
| `numero` do quarto duplicado (409 do backend) | Gerar número baseado em timestamp sufixado (ex: `"${DateTime.now().millisecondsSinceEpoch % 10000}${i}"`) como fallback |
| Catálogo vazio (`GET /:hotel_id/catalogo` retorna `[]`) | Exibir mensagem "Sem comodidades cadastradas" abaixo do seletor; seleção de comodidades é opcional |
| Foto grande causa timeout no upload | `maxWidth: 1000, maxHeight: 1000, imageQuality: 85` já configurado no `_pickImages` existente |
| `hotel_id` nulo (token expirado) | `loadCatalogo()` define `error: 'Sessão expirada. Faça login novamente.'` e bloqueia submit |
