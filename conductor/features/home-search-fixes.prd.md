# PRD — home-search-fixes

## Contexto
O app de reservas possui duas telas principais — home e busca — com problemas visuais e de usabilidade que afetam a primeira impressão do usuário e o fluxo principal de descoberta de acomodações.

## Problema
1. **Home Slide 1:** Título mal posicionado, logo e texto com espaçamento irregular e larguras diferentes
2. **Home Slide 2:** Conteúdo colado no topo, falta indicador de navegação abaixo do card
3. **RoomCard:** Avaliação separada das comodidades, preço ausente, nota sem casa decimal
4. **Search Page:** Logo descentralizado, conteúdo colado no topo, pesquisa da home não é herdada, filtro de comodidades ausente, cards diferentes da home, foto do card é do hotel e não do quarto

## Público-alvo
Usuários finais que utilizam o app mobile para buscar e reservar hospedagem.

## Requisitos Funcionais
1. Ajuste visual no slide 1 da home: descer título e aproximar logo do texto com mesma largura
2. Ajuste visual no slide 2 da home: adicionar padding top e indicadores de navegação abaixo do card
3. Reorganizar layout do RoomCard: avaliação ao lado das comodidades, exibir preço da diária, nota com 1 casa decimal
4. Centralizar logo no header da search page
5. Adicionar padding top no conteúdo da search page
6. Implementar herança de pesquisa: texto digitado na home deve ser passado para search e executar busca automaticamente
7. Adicionar filtro de comodidades na search page (reutilizar componente da home)
8. Padronizar cards da busca com os da home (mesmo widget)
9. Exibir foto do quarto específico no card da busca

## Requisitos Não-Funcionais
- [ ] Responsividade: funcionar em mobile (prioritário) e desktop
- [ ] Consistência visual: cards devem ter aparência idêntica em home e busca

## Critérios de Aceitação
- Dado que o usuário está no slide 1 da home, quando visualizar, então o título deve estar posicionado com padding adequado e logo/textos devem ter mesma largura e proximidade
- Dado que o usuário está no slide 2 da home, quando visualizar, então o conteúdo deve ter padding top e indicadores de navegação devem aparecer abaixo do card
- Dado que o usuário visualiza um RoomCard, então avaliação deve estar ao lado das comodidades, preço deve ser exibido, e nota deve ter 1 casa decimal
- Dado que o usuário está na search page, então o logo deve estar centralizado e conteúdo com padding top adequado
- Dado que o usuário digita uma pesquisa na home e toca em "Para onde você vai?", então a search page deve receber o texto e executar a busca automaticamente
- Dado que o usuário está na search page, então deve ver o filtro de comodidades igual ao da home
- Dado que o usuário visualiza cards na busca, então devem ter mesma aparência dos cards da home e fotos devem ser do quarto específico

## Fora de Escopo
- Modificações no backend para novos endpoints (apenas verificação de endpoint existente)
- Funcionalidade de reserva ou checkout
- Painel administrativo
- Testes automatizados