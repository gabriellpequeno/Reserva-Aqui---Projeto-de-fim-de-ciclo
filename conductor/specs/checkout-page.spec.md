# Spec — Checkout Page

## Referência
- **PRD:** conductor/features/checkout-page.prd.md
- **Task:** conductor/__task/P5-C-checkout-page.md

## Abordagem Técnica
Criar um `CheckoutNotifier` (AsyncNotifier) que carrega dados do quarto e configuração do hotel em paralelo no `build()`. O botão "Finalizar Reserva" dispara criação da reserva e geração do link de pagamento em sequência. A rota atual `/booking/checkout/:roomId` será atualizada para `/booking/checkout/:hotelId/:roomId`, pois todos os endpoints do hotel exigem `hotel_id`.

## Componentes Afetados

### Backend
Nenhuma alteração necessária — todos os endpoints já existem.

### Frontend
- **Novo:** `CheckoutNotifier` + `CheckoutState` (`lib/features/booking/presentation/notifiers/checkout_notifier.dart`)
- **Novo:** `BookingService` (`lib/features/booking/data/services/booking_service.dart`) — encapsula as 5 chamadas de API
- **Novo:** `ReservaModel` (`lib/features/booking/domain/models/reserva_model.dart`)
- **Novo:** `PagamentoModel` (`lib/features/booking/domain/models/pagamento_model.dart`)
- **Modificado:** `CheckoutPage` (`lib/features/booking/presentation/pages/checkout_page.dart`) — remover `_BookingMock`, consumir `CheckoutNotifier`, tratar estados de loading e erro
- **Modificado:** `app_router.dart` (`lib/core/router/app_router.dart`) — rota `/booking/checkout/:hotelId/:roomId`

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| `AsyncNotifier` em vez de `setState` | Padrão já consolidado no projeto (ver `FavoritesNotifier`, `HomeNotifier`) |
| Buscar dados do quarto e config do hotel em paralelo via `Future.wait` | Reduz tempo de carregamento inicial da tela |
| Separar `BookingService` de `UsuarioService` | `UsuarioService` já tem mais de 400 linhas; reservas são domínio distinto |
| Adicionar `hotelId` à rota `/booking/checkout/:hotelId/:roomId` | Todos os 5 endpoints precisam de `hotel_id`; sem ele a tela não funciona |

## Contratos de API

| Método | Rota | Auth | Body | Response |
|--------|------|------|------|----------|
| GET | `/:hotel_id/categorias/:id` | ❌ | — | `CategoriaQuartoModel` |
| GET | `/:hotel_id/configuracao` | ❌ | — | `ConfiguracaoHotelModel` |
| GET | `/:hotel_id/disponibilidade` | ❌ | `?checkin&checkout&categoria_id` | `{ disponivel: bool }` |
| POST | `/usuarios/reservas` | ✅ | `{ categoria_id, checkin, checkout, num_hospedes, hotel_id }` | `ReservaModel` |
| POST | `/hotel/reservas/:reserva_id/pagamentos` | ✅ | — | `PagamentoModel` |

## Modelos de Dados

```
ReservaModel {
  id: String
  categoriaId: int
  hotelId: String
  checkin: DateTime
  checkout: DateTime
  numHospedes: int
  status: String
  codigoPublico: String
}

PagamentoModel {
  reservaId: String
  linkPagamento: String
  status: String
}
```

## Dependências

**Bibliotecas:**
- [x] `dio` — chamadas HTTP (já no projeto)
- [x] `flutter_riverpod` — gerenciamento de estado (já no projeto)
- [x] `go_router` — navegação (já no projeto)

**Outras features:**
- [x] Auth (P0) — JWT necessário para POST de reserva e pagamento
- [x] RoomDetailsPage (P4-D) — origem da navegação; deve passar `hotelId` na rota
- [ ] TicketsPage (P5-D) — destino após criação da reserva (bloqueada por esta feature)

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| Reserva criada mas geração de pagamento falha | Exibir código público da reserva mesmo sem link de pagamento; não bloquear o usuário |
| Quarto reservado por outro usuário entre a checagem e o POST | Tratar erro 409 do backend com mensagem clara de indisponibilidade |
| `hotelId` não disponível no contexto de navegação vindo de outras telas | Garantir que `RoomDetailsPage` e demais origens passem `hotelId` ao navegar para `/booking/checkout/:hotelId/:roomId` |
