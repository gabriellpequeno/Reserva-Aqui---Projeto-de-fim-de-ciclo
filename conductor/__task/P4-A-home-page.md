# P4-A — home_page - feat/dynamic-room-listing

## Tela
`lib/features/home/presentation/pages/home_page.dart`

## Prioridade
**P4 — Listagens (Feature interna)**

## Branch sugerida
`feat/home-page-integration`

---

## Estado Atual
- Tela com dois "slides" verticais via PageView
- Slide 1: tela introdutória com imagem de fundo e botão "EXPLORAR"
- Slide 2: barra de busca estática ("Para onde você vai?") + lista horizontal de `RoomCard`
- Lista de cards hardcoded com 4 hotéis mockados
- Barra de busca sem funcionalidade — toque não faz nada
- Sem nenhuma chamada de API

---

## Lógica de negócio dos cards (Quartos Recomendados)

A lista deve seguir a seguinte ordem de fallback, resolvida **no backend**:

```
1. Quartos com avaliação → ordenar por média de avaliação DESC → retornar top N
2. Se nenhum quarto tiver avaliação mas hotéis tiverem → 1 quarto por hotel, hotéis ordenados por avaliação DESC
3. Se não houver nenhuma avaliação (hotel nem quarto) → 5 quartos/categorias aleatórios
```

> ⚠️ **Essa lógica requer um endpoint dedicado no backend.**
> Criar task **EXT-1** antes de iniciar esta integração.

---

## Barra de busca (Slide 2)

- O campo "Para onde você vai?" ao ser tocado deve **navegar para `search_page`** passando o foco para o campo de destino
- Não executa busca diretamente na home — serve como atalho de entrada para a search
- Não requer chamada de API

---

## O que integrar

### Cards de recomendação
- [ ] Criar `HomeNotifier` (Riverpod) com:
  - [ ] `rooms`: `List<Room>` (vazia por default)
  - [ ] `isLoading`: bool
  - [ ] `hasError`: bool
  - [ ] Método `loadRecommended()` que chama o novo endpoint EXT-1
- [ ] Ao entrar no slide 2 (ou ao montar a tela), chamar `loadRecommended()`
- [ ] Substituir a lista hardcoded pelo estado do `HomeNotifier`
- [ ] Para cada card, montar o `RoomCard` com dados reais:
  - `roomId` → id do quarto/categoria
  - `title` → nome do quarto ou categoria
  - `imageUrl` → buscar via `GET /uploads/hotels/:hotel_id/rooms/:quarto_id` (primeiro resultado)
  - `rating` → média de avaliação (ou vazio se não houver)
  - `amenities` → lista de ícones das comodidades vinculadas
- [ ] Tratar loading: exibir shimmer ou placeholder nos cards enquanto carrega
- [ ] Tratar erro: exibir mensagem discreta (não bloquear a tela inteira)
- [ ] Tratar lista vazia (não deve acontecer pelo fallback, mas cobrir)

### Barra de busca
- [ ] Adicionar `onTap` no campo "Para onde você vai?" para navegar até `/search` com foco no campo de destino
- [ ] Não requer estado nem API

---

## Endpoints usados

| Método | Rota                                              | Auth | Descrição                              |
|--------|---------------------------------------------------|------|----------------------------------------|
| GET    | `/quartos/recomendados` *(a criar — EXT-1)*       | ❌   | Quartos recomendados com fallback      |
| GET    | `/uploads/hotels/:hotel_id/rooms/:quarto_id`      | ❌   | Foto do quarto para o card             |

---

## Dependências
- **Requer:** EXT-1 (endpoint de recomendação no back), P0

## Bloqueia
— (folha)

---

## Observações
- O `RoomCard` já existe e está pronto para receber dados reais — não precisa ser alterado estruturalmente, apenas alimentado com dados da API.
- A navegação do card ao tocar já funciona (`/room_details/$roomId`) — só garantir que o `roomId` real está sendo passado.
