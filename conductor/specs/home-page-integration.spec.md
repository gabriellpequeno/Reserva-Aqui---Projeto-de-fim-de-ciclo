# Spec — Home Page Integration

## Referência
- **PRD:** conductor/features/home-page-integration.prd.md

## Abordagem Técnica
Duas frentes independentes no Flutter:

- **Barra de busca:** transformar o campo estático em um `GestureDetector` com dois comportamentos — toque no campo navega para `search_page` com foco no destino, toque no ícone de filtro abre um `DropdownMenu` com comodidades. Sem estado novo, sem chamada de API.
- **Cards de recomendação:** criar um `HomeNotifier` (`AsyncNotifier` Riverpod) que chama `GET /quartos/recomendados` ao montar o slide 2, substituindo a lista hardcoded por dados reais com shimmer durante o carregamento.

## Componentes Afetados

### Backend
- **Novo:** `recommendedRooms.service.ts` (`src/services/`) — lógica de recomendação com fallback (top rated → empate sorteado → 5 aleatórios)
- **Novo:** `recommendedRooms.controller.ts` (`src/controllers/`) — handler do endpoint EXT-1
- **Modificado:** `quarto.routes.ts` — registrar rota `GET /quartos/recomendados`
- **Novo:** `seed.recommendedRooms.ts` (`src/database/seeds/`) — seed com pelo menos 5 quartos com avaliações variadas para cobrir os 3 cenários de recomendação

### Frontend
- **Novo:** `home_notifier.dart` (`lib/features/home/presentation/notifiers/`) — `AsyncNotifier` com `loadRecommended()`
- **Novo:** `home_state.dart` (`lib/features/home/presentation/notifiers/`) — estado com `rooms`, `isLoading`, `hasError`
- **Novo:** `home_shimmer.dart` (`lib/features/home/presentation/widgets/`) — placeholder animado dos cards durante loading
- **Modificado:** `home_page.dart` — substituir lista hardcoded, adicionar comportamento da barra de busca e shimmer

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|---------------|
| `AsyncNotifier` em vez de `StateNotifier` | Padrão moderno do Riverpod — lida nativamente com loading/error/data sem boilerplate |
| Lógica de recomendação no backend | Evita expor todos os quartos via API só para ordenar no cliente |
| Dropdown de filtros na home sem navegação | Mantém a home leve, sem criar rota intermediária de filtros |

## Contratos de API

| Método | Rota | Body | Response |
|--------|------|------|----------|
| GET | `/api/quartos/recomendados` | — | `RecommendedRoom[]` |

### Shape de `RecommendedRoom`
```json
{
  "quarto_id": 1,
  "hotel_id": "uuid",
  "nome": "Suíte Master",
  "valor_diaria": "350.00",
  "nota_media": 4.9,
  "total_avaliacoes": 12,
  "imagem_url": "/uploads/hotels/:hotel_id/rooms/:quarto_id",
  "comodidades": ["wifi", "piscina", "estacionamento"]
}
```

## Modelos de Dados
Nenhuma tabela nova. A lógica de recomendação consulta as tabelas de quartos e avaliações já existentes via fan-out cross-tenant (`withTenant` + `masterPool`).

## Dependências

**Bibliotecas Flutter:**
- [ ] `shimmer` — placeholder animado durante loading dos cards
- [ ] `riverpod` — já em uso no projeto; `AsyncNotifier` para `HomeNotifier`

**Backend:**
- [ ] Acesso cross-tenant já implementado via `withTenant` + `masterPool`

**Outras features:**
- [ ] EXT-1 — endpoint `/quartos/recomendados` deve estar pronto antes da integração do frontend
- [ ] Search page já integrada — a home apenas navega para ela

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| Endpoint EXT-1 não pronto ao iniciar frontend | Mockar resposta localmente com os 5 quartos do seed durante desenvolvimento |
| Fan-out cross-tenant lento com muitos hotéis | Limitar a busca a top N tenants por nota + timeout por tenant |
| Imagem do quarto não encontrada | Exibir placeholder de imagem no `RoomCard` se URL retornar 404 |
| Sorteio igual a cada request no mesmo instante | Usar seed baseado em timestamp + `hotel_id` para garantir aleatoriedade real |
