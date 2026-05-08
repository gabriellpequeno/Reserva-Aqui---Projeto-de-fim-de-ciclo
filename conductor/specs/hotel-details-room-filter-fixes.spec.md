# Spec — Hotel Details Room Filter Fixes

## Referência
- **PRD:** `conductor/features/hotel-details-room-filter-fixes.prd.md`

## Abordagem Técnica

Correção puramente de layout em `hotel_details_page.dart`. O `Row` raiz do método `_buildBedFilter()` (linha 533) deve ser envolvido em `SingleChildScrollView(scrollDirection: Axis.horizontal)`, eliminando o `RenderFlex overflowed` quando há múltiplas opções de capacidade. Os chips já usam padding dinâmico sem largura fixa — nenhuma alteração adicional é necessária nos containers internos.

## Componentes Afetados

### Backend
Nenhum.

### Frontend
- **Modificado:** `_buildBedFilter()` — `Frontend/lib/features/rooms/presentation/pages/hotel_details_page.dart` (linha 533)
  - Envolver o `Row` raiz em `SingleChildScrollView(scrollDirection: Axis.horizontal)`

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| `SingleChildScrollView` em vez de `ListView.builder` horizontal | Número de chips é pequeno (≤ 6 capacidades distintas por hotel) — lazy loading desnecessário |
| Manter `Container` com padding dinâmico em vez de substituir por `Chip` nativo | Preserva o visual existente sem reescrever o widget |

## Contratos de API

Nenhum — mudança exclusivamente de layout.

## Modelos de Dados

Nenhum — nenhuma tabela ou model alterado.

## Dependências

**Bibliotecas:** nenhuma nova dependência.

**Serviços externos:** nenhum.

**Outras features:** nenhuma — `_buildBedFilter` é autocontido.

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| Scroll horizontal sobreposto ao scroll vertical da página | `SingleChildScrollView` horizontal dentro de `CustomScrollView` vertical é padrão Flutter suportado — eixos ortogonais não conflitam |
