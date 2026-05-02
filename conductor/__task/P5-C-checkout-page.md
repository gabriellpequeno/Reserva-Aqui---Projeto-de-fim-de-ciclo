# P5-C — checkout_page - feat/create-reservation

## Tela
`lib/features/booking/presentation/pages/checkout_page.dart`

## Prioridade
**P5 — Features Core (Feature mais interna)**

## Branch sugerida
`feat/checkout-page-integration`

## Rota
`/booking/checkout/:roomId`

---

## Estado Atual
Tela de checkout/confirmação de reserva. Dados mockados.

## O que integrar

- [ ] Ao entrar na tela, exibir resumo da reserva com base no `:roomId` e nos parâmetros passados (datas, hóspedes):
  - Buscar dados do quarto: `GET /:hotel_id/categorias/:id`
  - Calcular subtotal, impostos e total
- [ ] Exibir política do hotel (cancelamento, check-in): `GET /:hotel_id/configuracao`
- [ ] Botão "Confirmar reserva":
  - `POST /usuarios/reservas` — criar reserva
  - Body: `categoria_id`, `checkin`, `checkout`, `num_hospedes`, etc.
- [ ] Após criar reserva com sucesso:
  - Gerar link de pagamento: `POST /hotel/reservas/:reserva_id/pagamentos`
  - Exibir link/QR Code de pagamento (InfinitePay)
  - Redirecionar para `tickets_page` (P5-D) após confirmação
- [ ] Tratar estados:
  - [ ] Loading durante criação da reserva
  - [ ] Loading durante geração do link de pagamento
  - [ ] Erro de indisponibilidade (quarto já reservado nas datas)
  - [ ] Erro de autenticação
- [ ] Verificar disponibilidade antes de confirmar: `GET /:hotel_id/disponibilidade`

---

## Endpoints usados

| Método | Rota                                       | Auth | Descrição                        |
|--------|--------------------------------------------|------|----------------------------------|
| GET    | `/:hotel_id/categorias/:id`                | ❌   | Dados do quarto/categoria        |
| GET    | `/:hotel_id/configuracao`                  | ❌   | Políticas do hotel               |
| GET    | `/:hotel_id/disponibilidade`               | ❌   | Verificar disponibilidade        |
| POST   | `/usuarios/reservas`                       | ✅   | Criar reserva                    |
| POST   | `/hotel/reservas/:reserva_id/pagamentos`   | ✅   | Gerar link de pagamento          |

---

## Dependências
- **Requer:** P0, P2-A (autenticado como guest), P4-D (`room_details_page`)

## Bloqueia
- P5-D (`tickets_page`) — o ticket é gerado após a reserva

---

## Observações
- Nessa fase de desenvolvimento a tela de pagamento será apenas visual, sem conexão com ferramentas de pagamento reais.
- Avaliar se a tela exibe o voucher/código público da reserva após confirmação.
