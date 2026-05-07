# BUG-6 — favorites_page - Correções Visuais do Card de Favoritos

## Tela
`lib/features/favorites/presentation/pages/favorites_page.dart`
`lib/features/favorites/presentation/widgets/` (card de favorito)

## Prioridade
**Média** — visual quebrado na tela de favoritos do usuário

## Branch sugerida
`fix/favorites-card-fixes`

---

## Bugs

### Card de favorito

- [ ] **Título do card deve quebrar linha com no máximo 2 linhas** — adicionar `maxLines: 2` e `overflow: TextOverflow.ellipsis` no widget de texto do título; após 2 linhas o texto é truncado com `...`
- [ ] **Ícone de coração ao lado do botão "Ver mais"** — posicionar o ícone de coração (`Icons.favorite`, preenchido e na cor de destaque) ao lado do texto "Ver mais" no card; ao tocar no coração, remover dos favoritos
- [ ] **Foto do hotel/quarto deve aparecer no card** — o card deve exibir a foto correspondente ao favorito:
  - Se o favorito for um hotel: buscar via `GET /uploads/hotels/:hotel_id/cover`
  - Se o favorito for um quarto: buscar via `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`
  - Tratar o caso em que não há foto com um placeholder adequado (não deixar o espaço vazio/branco)

---

## Arquivos a modificar

| Arquivo | O que muda |
|---------|-----------|
| Widget do card de favorito | `maxLines: 2` no título, ícone coração ao lado de "Ver mais", exibir foto |
| `favorites_page.dart` | Garantir que os dados do favorito incluem `hotel_id` e `quarto_id` para buscar a foto |

---

## Observações
- Ao remover um favorito pela tela de favoritos (tocando no coração), o item deve desaparecer da lista imediatamente (optimistic update)
- Verificar se a resposta de `GET /usuarios/favoritos` retorna os IDs necessários para buscar as fotos; se não, adicionar ao endpoint
