# Spec — edit-room-page

## Referência
- **PRD:** conductor/features/edit-room-page.prd.md

## Abordagem Técnica

Converter `EditRoomPage` de `StatefulWidget` para `ConsumerStatefulWidget` (Riverpod), criando `EditRoomNotifier` + `EditRoomState` seguindo o mesmo padrão de `AddRoomNotifier`. Ao montar a tela, disparar `load(roomId)` que executa em paralelo onde possível: (1) `GET /hotel/me` para obter `hotel_id`, (2) `GET /hotel/quartos/:id` para dados do quarto, (3) a partir do `categoriaQuartoId` obtido, `GET /:hotel_id/categorias/:id` para dados da categoria, (4) `GET /uploads/hotels/:hotel_id/rooms/:quarto_id` para fotos existentes, (5) `GET /:hotel_id/catalogo` para o catálogo completo de comodidades.

O fluxo de `save()` é orquestrado pelo notifier sequencialmente: PATCH categoria → diff de comodidades (POST adicionadas / DELETE removidas) → PATCH quarto → DELETE fotos marcadas → POST fotos novas. O notifier expõe `saveStep: String?` para o indicador de progresso na página.

Gestão de comodidades por diff: a tela mantém `_selectedComodidadeIds` como `Set<int>` (inicializada com os IDs carregados da categoria). Na hora de salvar, o notifier calcula `adicionadas = selecionadas - atuais` e `removidas = atuais - selecionadas`, fazendo apenas as chamadas necessárias.

Fotos: a tela mantém `_fotosParaRemover` como `Set<String>` (IDs de fotos existentes marcadas para exclusão) e `_fotosNovas` como `List<XFile>` (arquivos selecionados da galeria). Fotos marcadas para remoção ficam visíveis com opacidade reduzida até o save confirmar a exclusão.

## Componentes Afetados

### Backend
- Nenhum endpoint novo. Todos os endpoints necessários já existem e estão funcionais.

### Frontend
- **Novo:** `EditRoomState` (`lib/features/rooms/presentation/notifiers/edit_room_state.dart`)
- **Novo:** `EditRoomNotifier` (`lib/features/rooms/presentation/notifiers/edit_room_notifier.dart`)
- **Modificado:** `edit_room_page.dart` — converter para `ConsumerStatefulWidget`, adicionar seção de comodidades com chips, implementar gestão real de fotos (carregar/remover/adicionar), exibir progresso de salvamento, recarregar `MyRoomsNotifier` ao sucesso, remover campos "Camas" e "Banheiros"

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| Notifier dedicado (`EditRoomNotifier`) | Fluxo de 6+ chamadas sequenciais com estado granular — segue padrão já estabelecido por `AddRoomNotifier` |
| `hotel_id` buscado via `GET /hotel/me` no notifier | Mesmo padrão de `MyRoomsNotifier` — autossuficiente, sem dependência de provider externo |
| Diff de comodidades calculado no notifier | Minimiza chamadas à API: só faz POST/DELETE das comodidades que realmente mudaram |
| Fotos removidas marcadas localmente antes de salvar | UX mais fluida: host vê a remoção imediatamente; DELETE só ocorre ao confirmar via "Salvar" |
| Remoção de fotos executada antes do upload das novas | Ordem determinística — evita estado ambíguo se o upload falhar após deletar |
| Campos "Camas" e "Banheiros" removidos | Não existem como campos separados na API; mantê-los criaria divergência entre UI e backend |
| Recarregar `MyRoomsNotifier` ao fechar | Garante que a lista reflete as alterações sem navegação manual do usuário |

## Contratos de API

| Método | Rota | Body | Response | Auth |
|--------|------|------|----------|------|
| GET | `/hotel/me` | — | `{ data: { hotel_id: string } }` | ✅ |
| GET | `/hotel/quartos/:id` | — | `{ data: QuartoModel }` | ✅ |
| GET | `/:hotel_id/categorias/:id` | — | `{ data: CategoriaQuartoModel }` | ❌ |
| GET | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | — | `{ fotos: [{ id, url }] }` | ✅ |
| GET | `/:hotel_id/catalogo` | — | `{ data: CatalogoItem[] }` | ❌ |
| PATCH | `/hotel/categorias/:id` | `{ nome, descricao, valor_diaria, capacidade_pessoas }` | `{ data: CategoriaQuartoModel }` | ✅ |
| POST | `/hotel/categorias/:id/itens` | `{ catalogo_id, quantidade }` | `{ data: CategoriaItemSafe }` | ✅ |
| DELETE | `/hotel/categorias/:id/itens/:catalogo_id` | — | `{ message }` | ✅ |
| PATCH | `/hotel/quartos/:id` | `{ disponivel: bool }` | `{ data: QuartoModel }` | ✅ |
| DELETE | `/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id` | — | `{ message }` | ✅ |
| POST | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | `FormData { foto: File }` | `{ fotos: [{ id, url }] }` | ✅ |

## Modelos de Dados

```
EditRoomState {
  loading: bool                           // carregamento inicial
  loadError: String?                      // erro ao carregar

  // IDs para chamadas subsequentes
  quartoId: String?
  categoriaId: String?
  hotelId: String?

  // catálogo e comodidades
  catalogoItens: List<CatalogoItemModel>  // catálogo completo do hotel
  comodidadesAtuais: Set<int>             // IDs carregados da categoria (referência para diff)

  // fotos
  fotosExistentes: List<FotoExistente>    // fotos já no servidor

  // submit
  saving: bool
  saveStep: String?                       // ex: "Atualizando categoria...", "Enviando fotos..."
  saveError: String?
  saveSuccess: bool
}

FotoExistente {
  id: String
  url: String
}
```

**Provider:** `editRoomNotifierProvider` como `AutoDisposeNotifierProvider` — sem argumento de família pois `roomId` é recebido via `load(roomId)` chamado no `initState` da página.

## Dependências

**Bibliotecas:**
- [x] `dio ^5.7.0` — cliente HTTP + `FormData`/`MultipartFile` para upload (já presente)
- [x] `flutter_riverpod ^3.3.1` — state management (já presente)
- [x] `image_picker` — seleção de imagens da galeria (já presente em `add_room_page.dart`)
- [x] `go_router ^17.2.1` — navegação (já presente)

**Serviços externos:** nenhum.

**Outras features:**
- [x] P0 — `dioProvider` com interceptor de autenticação
- [x] P2-A — login host (JWT válido)
- [x] P4-E — `my_rooms_page` — navega para esta tela e deve ser recarregada ao retornar
- [x] P5-A — `CatalogoItemModel` já criado em `lib/features/rooms/domain/models/catalogo_item.dart` (reutilizado)

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| PATCH categoria afeta todos os quartos da mesma categoria | Comportamento esperado e documentado — host edita a "categoria", não apenas uma unidade física |
| Remoção de foto falha após outras operações | Exibir SnackBar descritivo; fotos remanescentes ainda válidas; sem rollback |
| Catálogo vazio (`GET /:hotel_id/catalogo` retorna `[]`) | Exibir mensagem "Sem comodidades no catálogo"; seção de comodidades é opcional |
| Quarto não encontrado (404 no load) | Exibir estado de erro com botão de voltar; sem crash |
| Token expirado durante load | Interceptor do Dio dispara refresh automático; se falhar, `load()` define `loadError` |
| `numero` duplicado no quarto ao resubmeter (409) | Campo `numero` não é editado nesta tela — sem risco de conflito |
