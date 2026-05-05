# P5-E — ticket_details_page - feat/reservation-detail-cancel

## Tela
`lib/features/tickets/presentation/pages/ticket_details_page.dart`

## Prioridade
**P5 — Features Core (Feature mais interna)**

## Branch sugerida
`feat/ticket-details-page-integration`

## Rota
`/tickets/details/:ticketId`

---

## Estado Atual

Tela implementada com as seções:
- Endereço, Check-in / Check-out (data + hora), status, hóspedes, tipo de quarto
- Seção "Detalhes" com texto de descrição mockado + comodidades
- Card financeiro: subtotal, descontos, impostos, total

Sem integração real com API. Dados mockados no model `Ticket`.

---

## Ajustes de UI necessários (antes da integração)

### ➕ Adicionar: Nome do hóspede
- [ ] Adicionar campo `nomeHospede: String?` ao model `Ticket`
- [ ] Exibir na tela como linha de info (ex: ao lado ou abaixo do status)
- [ ] Fonte: `ReservaSafe.nome_hospede`

### ✅ Campo de horário — MANTER (com ajuste de mapeamento)
O campo existe no backend em dois contextos:

| Campo | Fonte | Disponibilidade |
|-------|-------|-----------------|
| Horário **padrão** do hotel (ex: "14:00") | `ConfiguracaoHotel.horario_checkin` / `horario_checkout` | Sempre disponível |
| Horário **real** de entrada/saída | `ReservaSafe.hora_checkin_real` / `hora_checkout_real` | Só após o evento |

- [ ] Exibir o horário padrão do hotel como referência sempre
- [ ] Se `hora_checkin_real` / `hora_checkout_real` estiverem preenchidos, substituir pelo horário real
- [ ] Adicionar campos `checkInTime` e `checkOutTime` ao model `Ticket` mapeando para horário padrão do hotel
- [ ] Adicionar campos opcionais `checkInRealTime` e `checkOutRealTime` para o horário real

### ✏️ Seção "Detalhes" — dividir em dois blocos
**Bloco 1 — Sobre o quarto** (confirmação do que foi reservado):
- Comodidades: lista de `CategoriaQuarto.itens` com ícone + nome + quantidade
- Capacidade máxima de pessoas

**Bloco 2 — Política do hotel** (regras e informações):
- Horário padrão de check-in e check-out (do hotel)
- Política de cancelamento (`ConfiguracaoHotel.politica_cancelamento`)
- Aceita animais (`ConfiguracaoHotel.aceita_animais`)

> Nota: `CategoriaQuarto` **não possui campo de descrição** — o bloco "Sobre o quarto" é composto apenas pelos itens/comodidades e capacidade.

---

## O que integrar

### Buscar dados da reserva
- [ ] Ao entrar na tela, chamar `GET /reservas/:codigo_publico` (rota pública)
- [ ] Mapear todos os campos do `ReservaSafe` para o model `Ticket`:

| Campo no `ReservaSafe` | Campo no `Ticket` |
|---|---|
| `codigo_publico` | `id` |
| `nome_hospede` | `nomeHospede` *(novo)* |
| `data_checkin` | `checkIn` |
| `data_checkout` | `checkOut` |
| `hora_checkin_real` | `checkInRealTime` *(novo, opcional)* |
| `hora_checkout_real` | `checkOutRealTime` *(novo, opcional)* |
| `num_hospedes` | `guestCount` |
| `tipo_quarto` | `roomType` |
| `valor_total` | `total` |
| `status` | `status` (mapear enum) |
| `observacoes` | — (exibir se não nulo) |

### Buscar dados do quarto (seção Detalhes — Bloco 1)
- [ ] Com `hotel_id` e `categoria_id` da reserva, chamar `GET /:hotel_id/categorias/:id`
- [ ] Exibir `itens` (comodidades) e `capacidade_pessoas`
- [ ] Buscar foto: `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`

### Buscar política do hotel (seção Detalhes — Bloco 2)
- [ ] Chamar `GET /:hotel_id/configuracao`
- [ ] Exibir:
  - `horario_checkin` / `horario_checkout` (horários padrão)
  - `politica_cancelamento` (texto livre, pode ser nulo — exibir somente se preenchido)
  - `aceita_animais` (boolean — exibir ícone/badge)

### Mapear status do back para o front

| Backend | Frontend | Regra |
|---|---|---|
| `SOLICITADA` | `aguardo` | direto |
| `AGUARDANDO_PAGAMENTO` | `aguardo` | direto |
| `APROVADA` + `hora_checkin_real == null` | `aprovado` | derivado |
| `APROVADA` + `hora_checkin_real != null` | `hospedado` | derivado |
| `CANCELADA` | `cancelado` | direto |
| `CONCLUIDA` | `finalizado` | direto |

### Cancelar reserva
- [ ] Botão "Cancelar" visível apenas quando status for `SOLICITADA` ou `AGUARDANDO_PAGAMENTO`
- [ ] Confirmação de dialog
- [ ] `PATCH /usuarios/reservas/:codigo_publico/cancelar`
- [ ] Atualizar status local e no `TicketsNotifier` (P5-D)

---

## Endpoints usados

| Método | Rota                                          | Auth | Descrição                    |
|--------|-----------------------------------------------|------|------------------------------|
| GET    | `/reservas/:codigo_publico`                   | ❌   | Dados completos da reserva   |
| GET    | `/:hotel_id/categorias/:id`                   | ❌   | Comodidades e capacidade     |
| GET    | `/:hotel_id/configuracao`                     | ❌   | Políticas do hotel           |
| GET    | `/uploads/hotels/:hotel_id/rooms/:quarto_id`  | ❌   | Foto do quarto               |
| PATCH  | `/usuarios/reservas/:codigo_publico/cancelar` | ✅   | Cancelar reserva             |

---

## Dependências
- **Requer:** P0, P2-A, P5-D (`tickets_page` com `codigo_publico`)

## Bloqueia
— (folha)

---

## Observações
- A rota `GET /reservas/:codigo_publico` é **pública** — pode ser acessada sem auth, útil para compartilhar voucher.
- O status `hospedado` não existe no backend — é derivado no front pela combinação `status === APROVADA && hora_checkin_real !== null`.
- `CategoriaQuarto.nome` pode ser usado como fallback de título do quarto se `tipo_quarto` da reserva vier vazio.
