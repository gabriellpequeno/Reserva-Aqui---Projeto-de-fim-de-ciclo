# P4-E — my_rooms_page - feat/host-room-listing

## Tela
`lib/features/rooms/presentation/pages/my_rooms_page.dart`

## Prioridade
**P4 — Listagens (Feature interna)**

## Branch sugerida
`feat/my-rooms-page-integration`

---

## Estado Atual
Lista de quartos do anfitrião. Dados mockados.

## O que integrar

- [ ] Ao entrar na tela, fazer `GET /hotel/quartos` para listar os quartos do hotel autenticado
- [ ] Complementar com `GET /hotel/categorias` para exibir categorias de quartos
- [ ] Criar `MyRoomsNotifier` (Riverpod) com:
  - [ ] Lista de quartos
  - [ ] Loading state
  - [ ] Método de refresh
- [ ] Para cada quarto, buscar foto: `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`
- [ ] Ação de deletar quarto:
  - [ ] Confirmação de dialog
  - [ ] `DELETE /hotel/quartos/:id`
  - [ ] Remover da lista local após sucesso
- [ ] Navegar para `edit_room_page` (P5-B) ao tocar em editar
- [ ] Navegar para `add_room_page` (P5-A) pelo FAB/botão de adicionar
- [ ] Tratar estado vazio (nenhum quarto cadastrado)

---

## Endpoints usados

| Método | Rota                                          | Auth | Descrição               |
|--------|-----------------------------------------------|------|-------------------------|
| GET    | `/hotel/quartos`                              | ✅   | Listar quartos do hotel |
| GET    | `/hotel/categorias`                           | ✅   | Listar categorias       |
| DELETE | `/hotel/quartos/:id`                          | ✅   | Deletar quarto          |
| GET    | `/uploads/hotels/:hotel_id/rooms/:quarto_id`  | ❌   | Fotos do quarto         |

---

## Dependências
- **Requer:** P0, P2-A (login host), P3-B (perfil host carregado com hotel_id)

## Bloqueia
- P5-A (`add_room_page`)
- P5-B (`edit_room_page`)
