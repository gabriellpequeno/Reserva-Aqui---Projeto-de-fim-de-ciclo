# Spec — home-search-fixes

## Referência
- **PRD:** conductor/features/home-search-fixes.prd.md

## Abordagem Técnica
Modificações visuais em widgets Flutter existentes (home_page, room_card, search_page) + implementação de navegação com passagem de parâmetro de query + reutilização de componente de filtro de comodidades. O RoomCard será modificado para exibir avaliação ao lado das comodidades, preço da diária, e nota com 1 casa decimal.

## Componentes Afetados

### Backend
- **Verificação:** `/quartos/recomendados` — verificar se retorna campo `preco` (float)
- **Verificação:** `/uploads/hotels/:hotel_id/rooms/:quarto_id` — verificar se retorna fotos do quarto

### Frontend
- **Modificado:** `home_page.dart` — ajustes de padding e alinhamento nos slides 1 e 2, botões de navegação
- **Modificado:** `room_card.dart` — reorganização de layout: avaliação ao lado das comodidades, campo de preço, formatação da nota com 1 casa decimal
- **Modificado:** `search_page.dart` — centralizar logo, padding top, herança de query da home, filtro de comodidades
- **Verificado:** `app_router.dart` — garantir que `/search` aceita parâmetro `query`

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|--------------|
| Reutilizar filtro de comodidades da home na search page | Evita duplicação de código e garante consistência |
| Usar o mesmo RoomCard para home e busca | Garante consistência visual entre as duas telas |
| Passar query via argumento de rota (extra) | Mais simples que queryParam para navegação interna |

## Contratos de API

| Método | Rota | Body | Response |
|--------|------|------|----------|
| GET | /quartos/recomendados | — | Verificar se retorna `preco` (float) |
| GET | /uploads/hotels/:hotel_id/rooms/:quarto_id | — | Fotos do quarto específico |

## Modelos de Dados
Nenhuma modificação de modelo de dados. Verificar apenas se:
- RoomCard (frontend) já tem campo `preco` mapeado
- Endpoint de recomendação retorna campo `preco`

## Dependências

**Bibliotecas:**
- Nenhuma nova dependência necessária

**Serviços externos:**
- Nenhum novo serviço necessário

**Outras features:**
- [ ] Filtro de comodidades da home — para reutilizar na search page
- [ ] RoomCard widget — para padronizar entre home e busca

## Riscos Técnicos
| Risco | Mitigação |
|-----|-----------|
| RoomCard modificado pode quebrar layout em outras telas | Testar todas as telas que usam o card |
| Query passadas entre telas pode ser null | Tratar caso vazio no SearchNotifier |
| Fotos do quarto podem não existir no endpoint | Ter fallback para foto do hotel |