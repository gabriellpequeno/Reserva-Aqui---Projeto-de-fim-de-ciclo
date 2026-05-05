# Plan — Hotel Details Room Filter Fixes

> Derivado de: conductor/specs/hotel-details-room-filter-fixes.spec.md
> Status geral: [PENDENTE]

---

## Setup & Infraestrutura [CONCLUÍDO]

Sem tasks — nenhuma migration, variável de ambiente ou dependência nova necessária.

---

## Backend [CONCLUÍDO]

Sem tasks — mudança exclusivamente no frontend.

---

## Frontend [CONCLUÍDO]

- [x] Envolver o `Row` raiz de `_buildBedFilter()` (linha 533) em `SingleChildScrollView(scrollDirection: Axis.horizontal)`
- [x] Verificar se há `Expanded` ou `Flexible` ancestral que impeça o scroll e removê-lo se existir

---

## Validação [PENDENTE]

- [ ] Hotel com múltiplas capacidades (ex: 1, 2, 3, 5 pessoas) exibe chips roláveis sem overflow
- [ ] Chip com label longo ("5 pessoas") não causa `RenderFlex overflowed`
- [ ] Selecionar um chip enquanto rola mantém o estado visual corretamente
- [ ] Em tela estreita (360dp) não há erro de layout
