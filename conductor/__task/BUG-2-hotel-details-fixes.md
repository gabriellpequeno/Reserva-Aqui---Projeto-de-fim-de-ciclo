# BUG-2 — hotel_details_page - Filtro de Quartos Rolável e Card Ajustável

## Tela
`lib/features/rooms/presentation/pages/hotel_details_page.dart`

## Prioridade
**Alta** — overflow visível quebrando a tela em uso real

## Branch sugerida
`fix/hotel-details-fixes`

---

## Bugs

### Aba "Quartos disponíveis" — filtro fixo

- [ ] **Fazer o filtro de tipos de quarto ser rolável lateralmente** — os chips/botões de filtro da aba de quartos devem estar em um `SingleChildScrollView` com `scrollDirection: Axis.horizontal` (ou `ListView.builder` horizontal) para que não quebrem o layout quando houver muitos tipos
- [ ] Remover qualquer `Expanded` ou `Flexible` que impeça o scroll horizontal dos filtros

### Card de tipo de quarto — overflow

- [ ] **Card do filtro ajustável ao tamanho do conteúdo** — o **card de filtro** (chip/botão de seleção de tipo de quarto, ex: "5 pessoas") é o que está causando `overflowed by 28 pixels`, não o card do quarto em si
  - Identificar o widget do card de filtro que gera o overflow (provavelmente um `Row` ou `Container` com largura fixa insuficiente para o texto)
  - Usar `IntrinsicWidth`, `FittedBox` ou remover largura fixa para que o card do filtro se ajuste ao conteúdo do label
  - Testar com labels curtos ("1 pessoa") e longos ("5 pessoas", nomes de categoria extensos)
  - Não usar tamanho fixo — o card de filtro deve crescer conforme o texto

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `hotel_details_page.dart` | Envolver filtros em scroll horizontal; corrigir overflow do card |
| Widget do card de quarto (identificar nome real) | Remover tamanho fixo, usar layout flexível |

---

## Como reproduzir o overflow
1. Entrar em um hotel que tenha quarto com capacidade para 5 pessoas (ou nome de categoria longo)
2. Observar o erro `RenderFlex overflowed by 28 pixels` na aba de quartos
