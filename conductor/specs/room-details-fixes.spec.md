# Spec — room-details-fixes

## Referência
- **PRD:** conductor/features/room-details-fixes.prd.md

## Abordagem Técnica

Três correções independentes no frontend, sem novos endpoints de backend:

1. **Título:** adicionar uma `Column` com dois `Text` widgets no topo do scroll da `room_details_page.dart`, usando dados já disponíveis no `RoomDetailsState` (`room.hotelName` e `room.categoria`).
2. **Disponibilidade:** a lógica de interpretação do campo `disponivel` já existe em `availability_checker.dart`; o bug suspeito é que o checkout chama `fetchDisponibilidade()` independentemente com os mesmos parâmetros mas pode divergir se as datas não forem propagadas corretamente via queryParams. A correção garante que as datas selecionadas no `AvailabilityChecker` sejam passadas fielmente ao checkout, e que ambas as telas interpretem `disponivel: false` como indisponível (sem inversão).
3. **Favoritar:** integrar o `favoritesProvider` já existente na `room_details_page.dart`, adicionando um `IconButton` no canto superior direito do Stack de header customizado.

## Componentes Afetados

### Backend
- Nenhum componente novo ou modificado — endpoint `GET /hotel/{hotelId}/disponibilidade` já existe e é utilizado por ambas as telas.

### Frontend

- **Modificado:** `room_details_page.dart` (`lib/features/rooms/presentation/pages/`) — adicionar título hierárquico, botão de favoritar com lógica de estado
- **Modificado:** `availability_checker.dart` (`lib/features/rooms/presentation/widgets/`) — auditar e corrigir interpretação do campo `disponivel` na resposta; garantir que o callback `onDatesChanged` propague as datas corretas
- **Modificado:** `checkout_page.dart` (`lib/features/booking/presentation/pages/`) — auditar se `verificarDisponibilidade()` interpreta `disponivel` da mesma forma que o `AvailabilityChecker`; unificar se houver divergência

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| Reutilizar `favoritesProvider` existente sem criar novo provider | O provider em `lib/features/favorites/presentation/providers/favorites_provider.dart` já expõe `isFavorite(hotelId)`, `addFavorite()` e `removeFavorite()` — duplicar seria desperdício |
| Optimistic update via `favoritesProvider.addFavorite/removeFavorite` com rollback em catch | Já é o padrão implementado no `FavoritesNotifier`; consistência com o resto do app |
| Não centralizar disponibilidade em provider separado neste momento | O escopo do bug é corrigir a interpretação, não refatorar a arquitetura; uma extração para `AvailabilityNotifier` seria uma task separada de refatoração |
| Título no body (topo do scroll) em vez de AppBar | A tela usa Stack customizado sem AppBar Flutter padrão; inserir Column no início do `ListView`/`SingleChildScrollView` é menos invasivo |

## Contratos de API

| Método | Rota | Body / Query | Response |
|--------|------|-------------|----------|
| GET | `/hotel/{hotelId}/disponibilidade` | `?data_checkin=YYYY-MM-DD&data_checkout=YYYY-MM-DD` | `[{ categoriaId, disponivel: bool, proxima_disponibilidade? }]` |
| POST | `/usuarios/favoritos` | `{ hotelId: string }` | `{ success: bool }` |
| DELETE | `/usuarios/favoritos/{hotelId}` | — | `{ success: bool }` |

## Modelos de Dados

Nenhum modelo novo. Modelos existentes relevantes:

```
RoomDetailsState {
  room: Room          // contém hotelName, categoria, fotos, amenidades
  categoriaId: int
}

FavoriteHotel {       // já existente em lib/features/favorites/
  hotelId: String
  hotelName: String
  ...
}
```

## Dependências

**Bibliotecas:**
- [ ] `flutter_riverpod` — já presente; usado para consumir `favoritesProvider` na `room_details_page`
- [ ] `dio` — já presente; usado pelo `booking_service` para chamada de disponibilidade

**Serviços externos:**
- Nenhum novo

**Outras features:**
- [x] Feature de favoritos (`lib/features/favorites/`) — provider e service já implementados, apenas integrar na tela de detalhes
- [x] Feature de autenticação — `authProvider` já expõe estado de autenticação; usar para guard do botão de favoritar

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| O backend retorna `disponivel` por categoria mas não por unidade individual | Auditar a resposta do endpoint com datas reais; se o campo não refletir unidades, abrir task de backend antes de concluir o fix |
| Datas do `AvailabilityChecker` não chegando corretamente ao checkout via queryParams | Adicionar log temporário no `onDatesChanged` durante desenvolvimento; verificar que o `GoRouter` serializa as datas em ISO 8601 |
| `favoritesProvider` não carregado na `room_details_page` (provider não escutado anteriormente) | Usar `ref.watch(favoritesProvider)` no `build` garante que o estado seja inicializado; o `FavoritesNotifier.build()` já chama `listFavoritos()` automaticamente |
| Usuário não autenticado acessa a tela (como guest) | Verificar `authProvider` antes de chamar `addFavorite`; se guest, redirecionar para `/login` via `context.push` |
