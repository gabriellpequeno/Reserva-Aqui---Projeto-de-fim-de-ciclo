# Spec — ticket-details-page-integration

## Referência
- **PRD:** conductor/features/ticket-details-page-integration.prd.md

## Abordagem Técnica
A `ticket_details_page` passa a ser autossuficiente: ao abrir, dispara três chamadas paralelas (`GET /reservas/:codigo_publico`, `GET /:hotel_id/categorias/:id`, `GET /:hotel_id/configuracao`) usando o `codigo_publico` como chave de navegação. Para isso, o backend expõe `codigo_publico` na listagem do usuário — adicionando a coluna à tabela `historico_reserva_global` via migration e atualizando o upsert e a query de listagem. No frontend, o model `Ticket` ganha novos campos e o `TicketsService` recebe os métodos de detalhe e cancelamento.

## Componentes Afetados

### Backend
- **Modificado:** `database/scripts/init_master.sql` — adicionar `ALTER TABLE historico_reserva_global ADD COLUMN IF NOT EXISTS codigo_publico UUID`
- **Novo:** `database/scripts/migrations/002_add_codigo_publico_to_historico.sql` — migration com ALTER + UPDATE para preencher registros existentes via join com `reserva_routing`
- **Modificado:** `src/services/reserva.service.ts`:
  - `HistoricoReservaSafe` — adicionar campo `codigo_publico: string`
  - `_upsertHistoricoGlobal` — adicionar parâmetro `codigoPublico` e coluna no INSERT (~5 call sites)
  - `_listReservasUsuario` — adicionar `codigo_publico` no SELECT

### Frontend
- **Modificado:** `lib/features/tickets/domain/models/ticket.dart` — adicionar campos `nomeHospede`, `checkInRealTime`, `checkOutRealTime`, `categoriaId`; corrigir `fromJson` para usar `codigo_publico` como `id`; corrigir `_mapStatus` para usar `hora_checkin_real != null` em vez de comparação por data
- **Modificado:** `lib/features/tickets/data/services/tickets_service.dart` — adicionar `fetchReservaByCodigoPublico`, `fetchCategoriaQuarto`, `fetchConfiguracaoHotel`, `cancelarReserva`
- **Modificado:** `lib/features/tickets/presentation/notifiers/tickets_notifier.dart` — adicionar método `cancelarReserva` com atualização local de estado
- **Modificado:** `lib/features/tickets/presentation/pages/ticket_details_page.dart` — integração completa: carregamento via API, `nomeHospede`, horários reais/padrão, Bloco 1 (comodidades + capacidade), Bloco 2 (política do hotel), botão cancelar com dialog

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| Adicionar `codigo_publico` ao `historico_reserva_global` em vez de usar `reserva_tenant_id + hotel_id` como chave de navegação | `codigo_publico` é a chave pública estável da reserva e a rota de detalhes é pública; padrão já adotado pelo time no PR #49 para `num_hospedes` |
| Chamar `GET /reservas/:codigo_publico` na details page em vez de reutilizar o cache | O cache (`HistoricoReservaSafe`) não tem `hora_checkin_real`, `observacoes` e outros campos necessários na tela de detalhes |
| Três chamadas paralelas com `Future.wait` na details page | As chamadas são independentes entre si — paralelismo reduz latência percebida |
| Dados de comodidades e política do hotel são opcionais | Se `categoriaId` for nulo ou a chamada falhar, os blocos são omitidos sem travar a tela |

## Contratos de API

| Método | Rota | Body | Response |
|--------|------|------|----------|
| GET | `/usuarios/reservas` | — | `HistoricoReservaSafe[]` — já existe, passa a incluir `codigo_publico` |
| GET | `/reservas/:codigo_publico` | — | `ReservaSafe` — público, já existe |
| GET | `/:hotel_id/categorias/:id` | — | `CategoriaQuarto` com `itens` e `capacidade_pessoas` — já existe |
| GET | `/:hotel_id/configuracao` | — | `ConfiguracaoHotel` com `horario_checkin`, `horario_checkout`, `politica_cancelamento`, `aceita_animais` — já existe |
| PATCH | `/usuarios/reservas/:codigo_publico/cancelar` | — | `void` — já existe |

## Modelos de Dados

```
historico_reserva_global (tabela master DB)
  + codigo_publico  UUID  NULL   -- adicionado via migration 002

HistoricoReservaSafe (type TypeScript)
  + codigo_publico: string

Ticket (model Dart)
  id              String   -- passa a ser codigo_publico (era reserva_tenant_id)
  + nomeHospede       String?
  + checkInRealTime   String?
  + checkOutRealTime  String?
  + categoriaId       int?
```

## Dependências

**Bibliotecas:**
- [x] `dio` — chamadas HTTP (já utilizado)
- [x] `flutter_riverpod` — gerenciamento de estado (já utilizado)

**Outras features:**
- [x] P0 — autenticação (JWT para o endpoint de cancelamento)
- [x] P2-A — cadastro de hotel (necessário para `hotel_id` e `categoria_id` na reserva)
- [x] P5-D — `tickets_page` com `codigo_publico` na navegação (PR #49 — item pendente no checklist)

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| Registros antigos em `historico_reserva_global` sem `codigo_publico` | Migration faz `UPDATE` via join com `reserva_routing` para preencher registros existentes; coluna fica nullable |
| `GET /:hotel_id/categorias/:id` pode falhar se `categoriaId` for nulo na reserva | Bloco 1 exibido condicionalmente — se `categoriaId == null`, seção de comodidades é omitida sem erro |
| Uma das três chamadas paralelas falha | `Future.wait` com tratamento individual; `ReservaSafe` é obrigatório, comodidades e política são opcionais |
| `codigo_publico` nulo em registros antigos após migration | `TicketCard` omite o botão "Detalhes" se `ticket.id` estiver vazio |
