# P5-B — edit_room_page - feat/update-room

## Tela
`lib/features/rooms/presentation/pages/edit_room_page.dart`

## Prioridade
**P5 — Features Core (Feature mais interna)**

## Branch sugerida
`feat/edit-room-page-integration`

## Rota
`/edit_room/:roomId`

---

## Estado Atual
Formulário de edição de um quarto existente. Sem integração com API.

## O que integrar

- [ ] Ao entrar na tela, pré-popular com dados existentes do quarto via `:roomId`:
  - `GET /hotel/quartos/:id` — dados do quarto
  - `GET /:hotel_id/categorias/:id` — dados da categoria vinculada
  - `GET /uploads/hotels/:hotel_id/rooms/:quarto_id` — fotos existentes
- [ ] Editar dados do quarto:
  - `PATCH /hotel/quartos/:id` — atualizar quarto físico
- [ ] Editar categoria do quarto:
  - `PATCH /hotel/categorias/:id` — atualizar nome, descrição, preço, capacidade
- [ ] Gerenciar comodidades:
  - Adicionar: `POST /hotel/categorias/:id/itens`
  - Remover: `DELETE /hotel/categorias/:id/itens/:catalogo_id`
- [ ] Gerenciar fotos:
  - Adicionar novas: `POST /uploads/hotels/:hotel_id/rooms/:quarto_id`
  - Remover existentes: `DELETE /uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id`
- [ ] Feedback de sucesso → voltar para `my_rooms_page` com lista atualizada

---

## Endpoints usados

| Método | Rota                                                  | Auth | Descrição                    |
|--------|-------------------------------------------------------|------|------------------------------|
| GET    | `/hotel/quartos/:id`                                  | ✅   | Dados do quarto              |
| GET    | `/:hotel_id/categorias/:id`                           | ❌   | Dados da categoria           |
| PATCH  | `/hotel/quartos/:id`                                  | ✅   | Atualizar quarto             |
| PATCH  | `/hotel/categorias/:id`                               | ✅   | Atualizar categoria          |
| POST   | `/hotel/categorias/:id/itens`                         | ✅   | Adicionar comodidade         |
| DELETE | `/hotel/categorias/:id/itens/:catalogo_id`            | ✅   | Remover comodidade           |
| POST   | `/uploads/hotels/:hotel_id/rooms/:quarto_id`          | ✅   | Adicionar foto               |
| DELETE | `/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id` | ✅   | Remover foto                 |

---

## Dependências
- **Requer:** P0, P2-A (host autenticado), P4-E (`my_rooms_page`)

## Bloqueia
— (folha)
