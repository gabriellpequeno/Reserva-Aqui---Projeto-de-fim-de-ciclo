# Plan — Favorites Page

> Derivado de: conductor/specs/favorites-page.spec.md
> Status geral: [CONCLUÍDO]

---

## Setup & Infraestrutura [CONCLUÍDO]

Sem tasks necessárias — tabela `hotel_favorito`, variáveis de ambiente e dependências já estão configuradas.

---

## Backend [CONCLUÍDO]

Sem tasks necessárias — controller, service e rotas já estão implementados e funcionais.

---

## Frontend [CONCLUÍDO]

- [x] Auditar referências ao modelo `FavoriteRoom` em todo o projeto (`searchProvider`, imports, etc.)
- [x] Renomear e adaptar `FavoriteRoom` → `FavoriteHotel` com campos do backend (`lib/features/favorites/domain/models/favorite_hotel.dart`)
- [x] Migrar `FavoritesNotifier` de `Notifier` para `AsyncNotifier` e substituir mocks por `Usuario.listFavoritos()` e `Usuario.removeFavorito()` (`lib/features/favorites/presentation/providers/favorites_provider.dart`)
- [x] Atualizar `FavoriteCard` para exibir dados do modelo novo, tratar `coverStoragePath` nulo com placeholder, e ajustar navegação para `/hotel_details/{hotelId}` (`lib/features/favorites/presentation/widgets/favorite_card.dart`)
- [x] Conectar botão de favorito na `RoomDetailsPage` a `Usuario.addFavorito()` / `Usuario.removeFavorito()` lendo estado via `favoritesProvider` (`lib/features/rooms/presentation/pages/room_details_page.dart`)

---

## Validação [PENDENTE]

- [ ] Autenticado: acessar página de favoritos e verificar que lista real do backend é exibida (sem dados mockados)
- [ ] Sem favoritos: verificar que estado vazio com mensagem informativa é exibido
- [ ] Remover favorito na página: item some da lista sem recarregar a página
- [ ] Favoritar na `RoomDetailsPage`: ícone de coração reflete estado correto ao voltar para a página de favoritos
- [ ] Não autenticado: tentar acessar favoritos e verificar redirecionamento para login
- [ ] Backend com erro: simular falha na API e verificar mensagem de erro amigável na tela
