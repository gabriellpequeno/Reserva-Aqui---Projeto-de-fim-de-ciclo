# Plan — Checkout Page

> Derivado de: conductor/specs/checkout-page.spec.md
> Status geral: [EM ANDAMENTO]

---

## Setup & Infraestrutura [CONCLUÍDO]

Nenhuma action necessária — sem migration, sem variável de ambiente nova, sem dependência nova.

---

## Backend [CONCLUÍDO]

Nenhuma action necessária — todos os endpoints já existem.

> Recomendado: confirmar contratos reais dos endpoints via Postman antes de integrar.

---

## Frontend [CONCLUÍDO]

- [x] Criar `ReservaModel` e `PagamentoModel` em `lib/features/booking/domain/models/`
- [x] Criar `BookingService` em `lib/features/booking/data/services/booking_service.dart` com os 4 métodos de API (pagamento removido — rota requer hotelGuard, inacessível pelo app do usuário)
- [x] Criar `CheckoutState` e `CheckoutNotifier` em `lib/features/booking/presentation/notifiers/checkout_notifier.dart`
- [x] Atualizar rota em `app_router.dart` para `/booking/checkout/:hotelId/:categoriaId` e garantir que `RoomDetailsPage` passe `hotelId` e `categoriaId` ao navegar
- [x] Refatorar `CheckoutPage`: remover `_BookingMock`, receber `hotelId` e `categoriaId`, consumir `CheckoutNotifier`
- [x] Implementar carregamento em paralelo dos dados do quarto e config do hotel (`Future.wait`)
- [x] Implementar verificação de disponibilidade antes de confirmar reserva
- [x] Implementar fluxo de confirmação: criar reserva → navegar para `/tickets` (geração de link de pagamento requer hotelGuard — fora de escopo desta fase)
- [x] Implementar tratamento de erros: indisponibilidade, autenticação (401), erro de conexão

> Nota: `POST /hotel/reservas/:reserva_id/pagamentos` usa `hotelGuard` — token de usuário é explicitamente rejeitado (403). Alinhado com a observação da task: "tela de pagamento apenas visual nesta fase".

---

## Validação [PENDENTE]

- [ ] Dados reais do quarto e política do hotel aparecem na tela ao abrir o checkout
- [ ] Fluxo completo: selecionar datas → confirmar → reserva criada → redirecionado para `/tickets`
- [ ] Erro de indisponibilidade: mensagem correta exibida quando quarto já está reservado nas datas selecionadas
- [ ] Erro de autenticação: redirecionamento para login quando token inválido ou ausente
- [ ] Banner de erro exibido e fechável quando a confirmação falha
