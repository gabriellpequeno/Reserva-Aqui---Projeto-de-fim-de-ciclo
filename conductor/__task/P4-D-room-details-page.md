# P4-D — room_details_page - feat/room-details-view

## Tela
`lib/features/rooms/presentation/pages/room_details_page.dart`

## Prioridade
**P4 — Listagens (Feature interna)**

## Branch sugerida
`feat/room-details-page-integration`

## Rota
`/room_details/:roomId`

---

## Estado Atual
Exibe detalhes de um quarto/categoria de quarto. Dados mockados com modelo `Room` local.

## O que integrar

- [ ] Ao entrar na tela, buscar dados com `:roomId` (que é `categoria_id`):
  - `GET /:hotel_id/categorias/:id` — dados detalhados da categoria de quarto
  - `GET /uploads/hotels/:hotel_id/rooms/:quarto_id` — fotos do quarto
- [ ] Mapear campos da resposta para o modelo `Room` existente:
  - título, descrição, preço, amenities, fotos, avaliação
- [ ] Exibir galeria de imagens do quarto
- [ ] Exibir lista de comodidades (itens do catálogo vinculados à categoria)
- [ ] Exibir dados do anfitrião (nome, bio, avaliação)
- [ ] Verificar disponibilidade:
  - [ ] `GET /:hotel_id/disponibilidade` — exibir datas disponíveis
- [ ] Botão de favoritar quarto/hotel:
  - [ ] `POST /usuarios/favoritos` — adicionar favorito
  - [ ] `DELETE /usuarios/favoritos/:hotel_id` — remover favorito
  - [ ] Verificar estado atual de favorito ao carregar
- [ ] Botão "Reservar" → `checkout_page` (P5-C) com `roomId`
- [ ] Tratar loading e erros

---

## Endpoints usados

| Método | Rota                                          | Auth | Descrição                    |
|--------|-----------------------------------------------|------|------------------------------|
| GET    | `/:hotel_id/categorias/:id`                   | ❌   | Detalhes da categoria/quarto |
| GET    | `/:hotel_id/disponibilidade`                  | ❌   | Verificar disponibilidade    |
| GET    | `/uploads/hotels/:hotel_id/rooms/:quarto_id`  | ❌   | Fotos do quarto              |
| POST   | `/usuarios/favoritos`                         | ✅   | Adicionar favorito           |
| DELETE | `/usuarios/favoritos/:hotel_id`               | ✅   | Remover favorito             |

---

## Dependências
- **Requer:** P0, P2-A (para ações autenticadas), P4-C (hotel_details como origem)

## Bloqueia
- P5-C (`checkout_page`)
