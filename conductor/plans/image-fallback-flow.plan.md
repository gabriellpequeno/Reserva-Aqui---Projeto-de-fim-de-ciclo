# Plan — Image Fallback Flow

> Derivado de: [conductor/specs/image-fallback-flow.spec.md](../specs/image-fallback-flow.spec.md)
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] `mock_room.jpg` já existia em `Frontend/lib/assets/` (registrado via `- lib/assets/` no pubspec.yaml)
- [x] Definir e validar URLs Unsplash do `_hotelMocks` (8 URLs) e do `_roomTypeMocks` (5 categorias + `_default`)

---

## Backend [CONCLUÍDO]

- [x] Sem tasks — escopo 100% frontend, backend permanece intocado conforme spec

---

## Frontend [CONCLUÍDO]

- [x] Criar `Frontend/lib/core/widgets/smart_network_image.dart`:
  - [x] `ConsumerStatefulWidget` com props `url`, `fallback`, `width`, `height`, `fit`
  - [x] HEAD pré-flight via `dioProvider`; cache em memória (`Map<String, bool>`) para evitar HEAD duplicado na mesma sessão
  - [x] Cancelamento de HEAD pendente em `didUpdateWidget` quando `widget.url` muda (evita race condition)
  - [x] `errorBuilder` final: tenta `lib/assets/mock_room.jpg`, depois `Container` sólido — nunca tenta outra URL de rede
  - [x] Função pura `fallbackForRoom(String? categoria)` retornando URL do `_roomTypeMocks` ou `_default`
  - [x] Função pura `fallbackForHotel(String hotelId)` retornando `_hotelMocks[hotelId.hashCode.abs() % _hotelMocks.length]`
  - [x] Constantes `_hotelMocks` (List<String>) e `_roomTypeMocks` (Map<String, String>) no mesmo arquivo
- [x] Integrar em `Frontend/lib/features/home/presentation/widgets/room_card.dart`:
  - [x] Substituir `Image.network` por `SmartNetworkImage` passando `imageUrl` e `fallback: fallbackForRoom(categoria)`
  - [x] Prop opcional `categoria` adicionada ao RoomCard
- [x] Integrar em `Frontend/lib/features/favorites/presentation/widgets/favorite_card.dart`:
  - [x] `firstCoverFotoId` mantido no model (backend já retorna o campo)
  - [x] Trocar `Image.network` + `_buildPlaceholder` por `SmartNetworkImage` com `fallback: fallbackForHotel(hotelId)`
- [x] Integrar em `pages/hotel_details_page.dart`:
  - [x] SliverAppBar: substituir `Image.network` por `SmartNetworkImage` com `fallback: fallbackForHotel(hotelId)`
  - [x] Avatar circular: substituir `DecorationImage(NetworkImage)` por `ClipOval + SmartNetworkImage`
- [x] Integrar em `notifiers/room_details_notifier.dart` + `pages/room_details_page.dart`:
  - [x] `_parseImageUrls` removeu lista hardcoded de 4 Unsplash; retorna `[]` quando sem fotos
  - [x] Imagem principal: substituir `DecorationImage(NetworkImage)` por `ClipRRect + SmartNetworkImage`
  - [x] Thumbnails: substituir `DecorationImage(NetworkImage)` por `ClipRRect + SmartNetworkImage`

---

## Validação [PENDENTE]

- [ ] **Critério: host com upload vê foto real** — Logar como host de hotel ativo, fazer upload de cover (portrait + landscape) e fotos de pelo menos 1 quarto. Abrir como hóspede e verificar que home/favoritos/detalhes do hotel/detalhes do quarto exibem as fotos reais (não mock)
- [ ] **Critério: host sem upload vê mock determinístico** — Para um hotel sem foto cadastrada, recarregar o app 3+ vezes e navegar entre páginas; confirmar que sempre o mesmo mock aparece (mesmo hotelId → mesma URL Unsplash)
- [ ] **Critério: registro órfão no BD cai em mock sem 404 visual** — Apontar `storage_path` no BD para um arquivo inexistente; abrir Network tab no DevTools e confirmar que: HEAD retorna 404, usuário vê mock instantaneamente sem flicker, GET para a URL real **não** é disparado
- [ ] **Critério: cache de HEAD funciona** — Em uma sessão, navegar para a mesma página do hotel 3 vezes; abrir Network tab e confirmar que HEAD para cada URL é disparado **apenas 1 vez** na sessão

---

## Regra de Atualização

- Todas `[ ]` → `[PENDENTE]`
- Algumas `[x]`, algumas `[ ]` → `[EM ANDAMENTO]`
- Todas `[x]` → `[CONCLUÍDO]`

Quando todas as seções estiverem `[CONCLUÍDO]`, atualizar **Status geral** no topo e sincronizar com `conductor/plan.md`.
