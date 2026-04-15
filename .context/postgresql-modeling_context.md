# Context: PostgreSQL Modeling

> Last updated: 2026-04-14T14:55:00-03:00
> Version: 8

## Purpose
Criação da tabela de Hotéis Favoritos no Master DB para sustentar features de retenção do App.

## Architecture / How It Works
- **Favoritos Globais (Wishlist)**: Adicionada a tabela de relacionamento N:N `hotel_favorito` no banco Master. Ela liga o `user_id` (hóspede global) ao `hotel_id` (anfitrião).
- Como essa funcionalidade precede a existência de reservas (fase de descoberta), ela foi estrategicamente alocada no banco global (Master) em vez das tenants. Foi aplicada uma restrição `UNIQUE` composta para evitar favoritismos duplicados.

## Affected Project Files
| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `Backend/database/scripts/init_master.sql` | Sim | Ajustes de rules/checks em ticket\_global e historico para suportar status APROVADA e novas vars |
| `Backend/database/scripts/init_tenant.sql` | Sim | Migração do modelo de pagamento para suportar full-webhook da InfinitePay e ajusta reservas/avaliação |

## Code Reference

### `Backend/database/scripts/init_tenant.sql` (v7 Additions)

```sql
CREATE TABLE IF NOT EXISTS pagamento_reserva (
    -- [relacionamentos base omitidos]
    checkout_url        TEXT,                                 -- Link de pagamento (InfinitePay)
    infinite_invoice_slug VARCHAR(100),                       -- Código da fatura (Webhook)
    transaction_nsu     VARCHAR(100),                         -- NSU da transação (Webhook)
...
```

**Key Design Decisions v7**: 
- Gateways financeiros foram absorvidos em nível de plataforma (variáveis de ambiente globais) por causa das taxas, portanto não foi criado tenant-based `infinite_tags`.
- Evita complexidade de Split Payment no Gateway delegando a distribuição de caixa baseada na métrica interna (`anfitriao.saldo`).

## Changelog

### v8 — 2026-04-14
- Adicionada tabela `hotel_favorito` no banco Master (`init_master.sql`) para armazenar os hotéis curtidos pelos usuários.

### v7 — 2026-04-14
- Refatoração dos fluxos de pagamentos e check constraints de Master e Tenant voltado para integração com InfinitePay baseando-se no payload do webhook oficial. Adicionado call to actions para inbox notification e alinhado constraints de tickets e avaliação de acordo com as regras de negócios.

### v6 — 2026-04-13
- Infraestrutura de FCM base construída na base master com rastreio central de dispositivos, reformulação do PENDENTE para nova pipeline corporativa (SOLICITADA -> AGU_PGT) e notificação corporativa per-tenant.

### v5 — 2026-04-13
- Adicionado sistema Global de Chats na `init_master.sql` (`sessao_chat` e `mensagem_chat`) cobrindo atendimento App e WhatsApp.

### v4 — 2026-04-13
- Adicionado módulo financeiro (`pagamento_reserva`), Soft Deletes e Cross-Schema FKs.

### v3 — 2026-04-13
- Migração completa e definitiva de Arch DB-per-Tenant para Schema-per-Tenant. Pools limitadas substituídas por roteador dinâmico.

### v2 — 2026-04-13
- Adicionada tabela `historico_reserva_global` para relatórios globais de visitantes.

### v1 — 2026-04-13
- Criação base da `ticket_reserva_global`.
