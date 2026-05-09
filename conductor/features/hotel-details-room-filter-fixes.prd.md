# PRD — Hotel Details Room Filter Fixes

## Contexto

A `HotelDetailsPage` possui uma aba "Quartos disponíveis" com chips de filtro por número de pessoas (ex: 1, 2, 3, 5 pessoas). O filtro já existe e funciona corretamente em termos de lógica, mas o layout dos chips está quebrando em uso real quando há múltiplas opções de capacidade ou valores mais altos.

## Problema

Os chips de filtro por número de pessoas na aba "Quartos disponíveis" transbordam o layout (`RenderFlex overflowed by 28 pixels`) quando há muitos valores de capacidade ou quando o label é maior (ex: "5 pessoas"). A ausência de scroll horizontal e o uso de largura fixa nos chips tornam a tela inutilizável nesses cenários.

## Público-alvo

Usuários hóspedes que navegam pelos detalhes de um hotel e filtram quartos disponíveis por capacidade de pessoas.

## Requisitos Funcionais

1. Os chips de filtro por número de pessoas devem ser roláveis lateralmente via `SingleChildScrollView(scrollDirection: Axis.horizontal)`
2. O chip de filtro deve se ajustar dinamicamente ao tamanho do label (sem largura fixa)
3. Nenhum `Expanded` ou `Flexible` deve impedir o scroll horizontal dos chips
4. O layout deve funcionar corretamente com valores curtos ("1 pessoa") e valores maiores ("5 pessoas")

## Requisitos Não-Funcionais

- [ ] Performance: sem impacto — mudança puramente de layout
- [ ] Segurança: não aplicável
- [ ] Acessibilidade: chips devem manter área de toque mínima (48×48dp)
- [ ] Responsividade: funcionar em telas pequenas (360dp) e grandes sem overflow

## Critérios de Aceitação

- Dado que o hotel possui quartos com várias capacidades (ex: 1, 2, 3, 5 pessoas), quando o usuário acessa a aba "Quartos disponíveis", então os chips de filtro por número de pessoas devem ser roláveis horizontalmente sem overflow
- Dado que um chip exibe um número alto de pessoas (ex: "5 pessoas"), quando é renderizado, então deve se expandir dinamicamente para acomodar o texto sem causar overflow
- Dado que o usuário seleciona um chip de filtro, quando rola a lista horizontal, então o chip selecionado mantém seu estado visual
- Dado qualquer dispositivo com tela ≥ 360dp, quando a aba de quartos é exibida, então não deve aparecer nenhum erro `RenderFlex overflowed`

## Fora de Escopo

- Alteração na lógica de filtro (o que filtra, como filtra)
- Redesign visual dos chips (cores, tipografia, forma)
- Integração ou mudança nos dados retornados pela API
- Qualquer outra aba da `HotelDetailsPage` que não seja "Quartos disponíveis"
