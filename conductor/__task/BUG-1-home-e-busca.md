# BUG-1 — home_page + search_page - Correções Visuais, Herança de Pesquisa e Padronização

## Telas
`lib/features/home/presentation/pages/home_page.dart`
`lib/features/home/presentation/widgets/room_card.dart` (ou equivalente)
`lib/features/search/presentation/pages/search_page.dart`
`lib/features/search/presentation/widgets/` (cards da busca)

## Prioridade
**Alta** — primeira impressão do app + fluxo principal de descoberta

## Branch sugerida
`fix/home-search-fixes`

---

## Bugs e Ajustes — Home Screen 1 (slide introdutório)

- [ ] **Descer o título** — verificar padding/posição do texto principal no slide 1; adicionar `paddingTop` ou ajustar `Alignment`
- [ ] **Logo e texto mais próximos + igualar largura** — reduzir espaçamento vertical entre logo e slogan; aplicar mesma `width constraint` (ex: `SizedBox` ou `FractionallySizedBox`) para que ambos ocupem a mesma largura e fiquem alinhados

## Bugs e Ajustes — Home Screen 2 (slide de listagem)

- [ ] **Descer conteúdo** — adicionar padding top ou ajustar `SafeArea` / `SliverPadding` no slide 2
- [ ] **Botão sutil abaixo do card** — já existe um botão de avançar acima do card; adicionar um indicador/botão mais sutil (ex: dots ou setas discretas) posicionado **abaixo** do card para complementar a navegação
  - O swipe horizontal no mobile deve continuar funcionando normalmente — os botões são complemento visual, não substituição do gesto
  - O estilo deve ser sutil (não competir visualmente com o card)
- [x] **Avaliação ao lado das comodidades** — ícones de comodidades carregados via `_parseAmenities` + `_iconForAmenity`; layout do `RoomCard` já posiciona rating e ícones na mesma linha
- [x] **Preço no card** — endpoint `/quartos/recomendados` retorna `preco`; exibido no card
- [x] **Nota com 1 casa decimal** — backend retorna `ROUND(AVG(a.nota_total), 1)`; formatação preservada como string

---

## Bugs e Ajustes — Search Page

- [ ] **Centralizar logo** — verificar alinhamento do logo no header; aplicar `Center` ou `mainAxisAlignment: MainAxisAlignment.center`
- [ ] **Descer conteúdo** — adicionar padding top ou ajustar `SafeArea` para o conteúdo não ficar colado no topo
- [x] **Herdar pesquisa da home e executar** — home passa `query` + `amenities` via `extra`; `SearchPage.initState` pré-preenche o campo e dispara `performSearch()`
- [x] **Filtro de comodidade** — chips idênticos em home e search; `_filterOptions` usa nomes exatos do catálogo; `updateAmenities()` + `performSearch()` conectados; backend aplica filtro AND por EXISTS
- [x] **Padronizar card com os da home** — mesmo `RoomCard` widget em ambas as telas
- [x] **Foto do card deve ser a do quarto** — `foto_id` vem de `quarto_foto` via subquery; URL montada como `/api/v1/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id`; `UPLOAD_DIR` em `/home/levimat/.reservaqui-storage` persiste entre restarts

---

## Relação Home → Search (herança de estado)

```
Home slide 2
  └─ usuário toca em "Para onde você vai?"
       └─ navega para /search passando query atual (pode ser vazio)
            └─ SearchPage monta com query pré-preenchida
                 └─ se query não vazia: dispara busca imediatamente
```

- Garantir que a rota `/search` aceita `query` como parâmetro (queryParam ou `extra`)
- Na `SearchPage`, consumir esse parâmetro no `initState` ou via `ref.listen`

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| `home_page.dart` | Padding slide 1 e 2, alinhamento logo/título, botões de navegação |
| `room_card.dart` | Layout: avaliação ao lado das comodidades, campo de preço, formatação da nota |
| `search_page.dart` | Centralizar logo, padding, receber e disparar query da home, filtro de comodidade |
| `app_router.dart` | Garantir que `/search` aceita parâmetro `query` |
| Endpoint `/quartos/recomendados` (backend) | Verificar se retorna `preco` com precisão float |

---

## Dependências
- BUG-1 não bloqueia outras tasks de bug
- Se o filtro de comodidade precisar de endpoint novo no backend, criar task EXT antes de implementar o filtro

## Observações
- O `RoomCard` é compartilhado — qualquer alteração no widget afeta home e busca simultaneamente; testar os dois contextos após cada mudança
- Não duplicar o card: se hoje existem dois widgets separados para home e busca, unificar em um só
