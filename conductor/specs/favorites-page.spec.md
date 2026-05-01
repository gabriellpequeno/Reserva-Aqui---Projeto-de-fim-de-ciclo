# Spec — Favorites Page

## Referência
- **PRD:** conductor/features/favorites-page.prd.md

## Abordagem Técnica
O backend já está completamente implementado (controller, service, rotas em `/api/usuarios/favoritos`). O `Usuario.dart` no Flutter também já possui os três métodos de API (`listFavoritos`, `addFavorito`, `removeFavorito`). O trabalho se concentra inteiramente no Frontend: substituir os mocks do `FavoritesNotifier` por chamadas reais, adaptar o modelo `FavoriteRoom` para refletir a resposta do backend (baseada em hotel, não em quarto), e sincronizar o botão de favorito na `RoomDetailsPage`.

## Componentes Afetados

### Backend
Nenhuma alteração necessária — controller, service e rotas já estão implementados e funcionais.

### Frontend
- **Modificado:** `FavoriteRoom` (`lib/features/favorites/domain/models/favorite_room.dart`) — adaptar campos para bater com `FavoritoComHotel` do backend (`hotel_id`, `nome_hotel`, `cidade`, `uf`, `cover_storage_path`, `favoritado_em`)
- **Modificado:** `FavoritesNotifier` (`lib/features/favorites/presentation/providers/favorites_provider.dart`) — substituir mock por chamadas reais a `Usuario.listFavoritos()` e `Usuario.removeFavorito()`; migrar de `Notifier` para `AsyncNotifier`
- **Modificado:** `FavoriteCard` (`lib/features/favorites/presentation/widgets/favorite_card.dart`) — ajustar navegação para `/hotel_details/{hotel_id}` em vez de `/room_details/{id}`
- **Modificado:** `RoomDetailsPage` (`lib/features/rooms/presentation/pages/room_details_page.dart`) — conectar botão de favorito a `Usuario.addFavorito()` / `Usuario.removeFavorito()` via `favoritesProvider`

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| Manter `FavoritesNotifier` como fonte única de verdade | Evita chamadas duplicadas e garante consistência do estado entre telas |
| Backend retorna hotéis (não quartos): adaptar modelo Flutter diretamente | Sem criar abstração intermediária desnecessária — o modelo reflete exatamente o contrato da API |
| Migrar para `AsyncNotifier` em vez de `Notifier` | Permite exibir estados de loading e erro nativamente no Riverpod sem boilerplate extra |

## Contratos de API

| Método | Rota | Body | Response |
|--------|------|------|----------|
| GET | `/api/usuarios/favoritos` | — | `FavoritoComHotel[]` (200) |
| POST | `/api/usuarios/favoritos` | `{ hotel_id: string }` | `FavoritoComHotel` (201) |
| DELETE | `/api/usuarios/favoritos/:hotel_id` | — | 204 No Content |

Todos os endpoints exigem header `Authorization: Bearer <token>`.

**Erros mapeados:**
- `401` — token inválido ou expirado
- `404` — hotel não encontrado
- `409` — hotel já favoritado

## Modelos de Dados

**Backend — tabela `hotel_favorito` (já existe):**
```
hotel_favorito {
  id:         uuid
  user_id:    uuid
  hotel_id:   uuid
  criado_em:  timestamp
}
```

**Backend — interface `FavoritoComHotel` (retorno da API):**
```
FavoritoComHotel {
  hotel_id:           string
  nome_hotel:         string
  cidade:             string
  uf:                 string
  bairro:             string
  descricao:          string | null
  cover_storage_path: string | null
  favoritado_em:      Date
}
```

**Frontend — `FavoriteRoom` a renomear/adaptar para `FavoriteHotel`:**
```dart
FavoriteHotel {
  hotelId:          String
  nomeHotel:        String
  cidade:           String
  uf:               String
  bairro:           String
  descricao:        String?
  coverStoragePath: String?
  favoritadoEm:     DateTime
}
```

## Dependências

**Bibliotecas (já instaladas):**
- [x] `dio` — cliente HTTP para chamadas à API
- [x] `flutter_riverpod` — gerenciamento de estado
- [x] `go_router` — navegação entre telas

**Outras features:**
- [x] Feature de autenticação — token JWT necessário para todos os endpoints
- [x] Hotel Details Page — destino do tap no card de favorito

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| Modelo `FavoriteRoom` referenciado em outros providers (ex: `searchProvider`) | Auditar e atualizar todas as referências antes de renomear o modelo |
| Estado de favorito desincronizado entre `FavoritesPage` e `RoomDetailsPage` | `RoomDetailsPage` lê e atualiza via `favoritesProvider` em vez de manter estado local |
| Imagem do hotel via `cover_storage_path` pode ser `null` | Exibir placeholder no `FavoriteCard` quando o campo for `null` |
