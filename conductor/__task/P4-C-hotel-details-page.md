# P4-C — hotel_details_page - feat/hotel-details-view

## Tela
`lib/features/rooms/presentation/pages/hotel_details_page.dart`

## Prioridade
**P4 — Listagens (Feature interna)**

## Branch sugerida
`feat/hotel-details-page-integration`

## Rota
`/hotel_details/:hotelId`

---

## Estado Atual
Exibe detalhes de um hotel recebendo `:hotelId` via rota. Dados possivelmente mockados.

## O que integrar

- [ ] Ao entrar na tela, fazer as chamadas com o `hotel_id` recebido por rota:
  - `GET /hotel/:hotel_id/me` — dados públicos do hotel *(verificar se existe rota pública ou só autenticada)*
  - `GET /uploads/hotels/:hotel_id/cover` — fotos de capa
  - `GET /:hotel_id/avaliacoes` — avaliações e nota média
  - `GET /:hotel_id/catalogo` — comodidades do hotel
  - `GET /:hotel_id/configuracao` — políticas (check-in/checkout, regras)
- [ ] Exibir galeria de imagens a partir das fotos retornadas
- [ ] Exibir avaliações dos hóspedes (lista ou resumo)
- [ ] Exibir comodidades (catalogo)
- [ ] Exibir políticas do hotel (configuracao)
- [ ] Botão "Ver quartos" → listar categorias via `GET /:hotel_id/categorias` → navegar para `room_details_page` (P4-D)
- [ ] Tratar loading states para cada chamada
- [ ] Tratar erros (hotel não encontrado, 404)

---

## Endpoints usados

| Método | Rota                                      | Auth | Descrição                  |
|--------|-------------------------------------------|------|----------------------------|
| GET    | `/:hotel_id/catalogo`                     | ❌   | Comodidades do hotel       |
| GET    | `/:hotel_id/categorias`                   | ❌   | Tipos de quarto            |
| GET    | `/:hotel_id/configuracao`                 | ❌   | Políticas do hotel         |
| GET    | `/hotel/:hotel_id/avaliacoes`              | ❌   | Avaliações do hotel        |
| GET    | `/uploads/hotels/:hotel_id/cover`         | ❌   | Fotos de capa              |

---

## Dependências
- **Requer:** P0, P4-A ou P4-B (origin de navegação)

## Bloqueia
- P4-D (`room_details_page`)
- P5-C (`checkout_page` — fluxo de reserva começa aqui)

---

## Observações
- Verificar se existe rota pública `GET /hotel/:hotel_id` para dados básicos do hotel sem autenticação. Se não existir, levantar task EXT.
