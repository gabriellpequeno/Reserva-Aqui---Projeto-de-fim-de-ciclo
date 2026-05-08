# BUG-7 — tickets_page + ticket_details_page - Status, Lógica de Fluxo e Tela de Detalhe

## Telas
`lib/features/tickets/presentation/pages/tickets_page.dart`
`lib/features/tickets/presentation/pages/ticket_details_page.dart`

## Prioridade
**Alta** — tela de detalhe não funcional + fluxo de status incorreto

## Branch sugerida
`fix/tickets-status-and-details`

---

## Bugs

### 1. Padronizar status e filtros

- [ ] **Alinhar nomenclatura de status** entre backend e frontend — os status devem ser consistentes nos dois lados:

  | Status | Quando ocorre |
  |--------|--------------|
  | `Aguardo` | Reserva criada pelo usuário, aguardando aprovação do hotel |
  | `Em Andamento` | Hotel aprovou a reserva |
  | `Hospedado` | Data de check-in foi atingida |
  | `Finalizado` | Data de checkout foi atingida OU hotel marcou como finalizado |
  | `Cancelado` | Hotel não aprovou, hotel cancelou ou usuário cancelou |

- [ ] **Filtros de status na `tickets_page`** devem usar exatamente os mesmos labels acima — sem variações (ex: "Aprovado" vs "Em Andamento" — padronizar)
- [ ] Verificar se os chips de filtro na tela cobrem todos os 5 status

### 2. Lógica de transição de status

- [ ] **Verificar e corrigir as transições no backend:**
  - Reserva criada → `AGUARDANDO`
  - Hotel aprova → `APROVADA` / `EM_ANDAMENTO`
  - Data de check-in chegou (job agendado ou verificação na abertura) → `HOSPEDADO`
  - Data de checkout chegou OU hotel altera manualmente → `FINALIZADO`
  - Hotel rejeita / cancela / usuário cancela → `CANCELADO`
- [ ] **No frontend**, garantir que o mapeamento de status do backend para os labels de exibição está correto (verificar o `switch`/`map` de status no notifier ou no widget)

### 3. Tela de detalhe do ticket não funcional

**Erro atual:** "Não foi possível carregar os dados da reserva"

- [ ] Identificar o endpoint chamado pela `ticket_details_page` e o parâmetro passado (`codigo_publico` ou `id`)
- [ ] Verificar se o endpoint `GET /usuarios/reservas/:codigo_publico` (ou equivalente) está retornando dados corretamente — testar via Postman/cURL
- [ ] Verificar se o `codigo_publico` está sendo passado corretamente na navegação da `tickets_page` → `ticket_details_page`
- [ ] Verificar se o modelo `Ticket` no front mapeia todos os campos retornados pelo endpoint (campos faltantes causam erro silencioso de deserialização)
- [ ] Após corrigir, garantir que todos os campos relevantes são exibidos: código, status, datas, hotel, quarto, total, forma de pagamento

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `tickets_page.dart` | Padronizar labels de filtro de status |
| `ticket_details_page.dart` | Corrigir carregamento de dados |
| Notifier/provider dos tickets | Corrigir mapeamento de status e parâmetro de navegação |
| Backend (se necessário) | Verificar endpoint de detalhe e transições de status |

---

## Dependências
- BUG-9 (Agendamentos do Host) depende desta task indiretamente — o fluxo de aprovação do host altera o status do ticket

## Como reproduzir o erro da tela de detalhe
1. Entrar em Tickets como usuário com reserva existente
2. Tocar em qualquer ticket
3. Observar erro "Não foi possível carregar os dados da reserva"
