# BUG-8 — host - Agendamentos, Meus Quartos e Estado de Login

## Telas
`lib/features/bookings/presentation/pages/` (tela de agendamentos do host — a criar ou integrar)
`lib/features/rooms/presentation/pages/my_rooms_page.dart`
`lib/core/auth/auth_notifier.dart`

## Prioridade
**Alta** — funcionalidade de aprovação de reservas não existe + bug crítico de dados entre contas

## Branch sugerida
`fix/host-bookings-and-auth-state`

---

## Bugs

### 1. Tela de Agendamentos do Host — Não funcional

**Comportamento esperado:** tela semelhante à `tickets_page` do usuário, mas voltada ao host para gerenciar as reservas recebidas.

- [ ] **Criar ou integrar a tela de agendamentos do host**
  - Layout similar à `tickets_page`: lista de reservas com chips de status e filtro
  - Exibir por reserva: código público, nome do hóspede, quarto, datas, total, status atual
- [ ] **Ações disponíveis para o host:**
  - Aprovar reserva em `Aguardo` → muda status para `Em Andamento`
  - Cancelar reserva → muda status para `Cancelado`
  - Marcar como `Finalizado` (quando aplicável)
- [ ] **Fluxo de aprovação:**
  - `PATCH /hotel/reservas/:reserva_id` com `{ status: 'APROVADA' }` (verificar endpoint correto)
  - Após aprovação, o ticket do usuário deve refletir o novo status (ver BUG-7)
- [ ] Tratar estado vazio (nenhuma reserva recebida)
- [ ] Pull-to-refresh

### 2. Meus Quartos — Não permitir exclusão com reserva ativa

**Regra de negócio:**
- Se o quarto tiver **reservas ativas** (status `AGUARDANDO` ou `EM_ANDAMENTO`):
  - E o número de reservas ativas for **igual ou maior** ao total de unidades do quarto → **só permitir desativar** (não excluir)
  - E o número de reservas ativas for **menor** que o total de unidades → permitir exclusão (as unidades sem reserva podem ser removidas)
- Se não houver reservas ativas → permitir exclusão normalmente

- [ ] Verificar endpoint que retorna reservas ativas por quarto, ou adaptar a verificação na lógica de exclusão
- [ ] Ao tentar excluir um quarto com reservas ativas que impedem exclusão, exibir diálogo explicativo: "Este quarto possui reservas ativas. Desative-o para que não receba novas reservas."
- [ ] Implementar ação de **desativar quarto** (flag `ativo: false` via `PATCH /:hotel_id/categorias/:id`)
- [ ] Quarto desativado não aparece nas buscas nem na listagem pública, mas mantém as reservas existentes

### 3. Estado de Login não limpo ao trocar de conta Host

**Comportamento atual (incorreto):**
- Login hotel 1 → logout → login hotel 2 → dados cadastrais exibidos são do hotel 1

**Causa provável:**
- O `AuthNotifier` ou o provider de perfil do host está cacheando dados sem invalidar ao fazer logout
- O logout não está chamando `ref.invalidate()` nos providers de perfil

- [ ] No método de logout do `AuthNotifier`, garantir que **todos** os providers de dados do usuário/host são invalidados:
  - `hostProfileProvider` (ou equivalente)
  - `userProfileProvider`
  - Qualquer outro provider que cacheia dados do usuário logado
- [ ] Após logout e novo login, os providers devem buscar os dados do novo usuário do zero
- [ ] Testar o fluxo: login hotel 1 → logout → login hotel 2 → verificar que nome, email e dados do hotel 2 aparecem corretamente

---

## Endpoints usados

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| GET | `/hotel/reservas` | ✅ | Reservas recebidas pelo hotel |
| PATCH | `/hotel/reservas/:id` | ✅ | Atualizar status da reserva |
| PATCH | `/:hotel_id/categorias/:id` | ✅ | Desativar quarto |

---

## Dependências
- BUG-7 (tickets do usuário) — o status alterado pelo host aqui deve refletir no ticket do usuário
- Fix de estado de login (item 3) deve ser feito **antes** dos testes de fluxo de agendamento para garantir ambiente limpo
