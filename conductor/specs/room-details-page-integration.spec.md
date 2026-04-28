# Spec — Room Details Page Integration

## Referência
- **PRD:** conductor/features/room-details-page-integration.prd.md

## Abordagem Técnica

A tela `RoomDetailsPage` atualmente renderiza dados mockados. A integração ocorre em três frentes independentes:

1. **Dados do quarto:** criar um endpoint público `GET /api/hotel/:hotel_id/quartos/:quarto_id` que retorna dados completos do quarto (físico + categoria + itens). O frontend consome esse endpoint via `RoomDetailsNotifier` (Riverpod).
2. **Verificação de disponibilidade:** usar o endpoint existente `GET /api/hotel/:hotel_id/disponibilidade` para checar disponibilidade por categoria nas datas selecionadas.
3. **Favoritar:** usar `POST /api/usuarios/favoritos` e `DELETE /api/usuarios/favoritos/:hotel_id` (autenticados) com redirect para login se não autenticado.

**Investigação resolvida sobre IDs:** A navegação atual usa `quarto_id` (ID do quarto físico, retornado tanto pelos quartos recomendados quanto pela busca). A opção de usar `GET /:hotel_id/categorias/:id` (com `categoria_id`) foi descartada porque exigiria tradução de IDs em dois pontos (home + busca). A solução é criar um endpoint público que aceita `quarto_id` diretamente, fazendo o join interno com `categoria_quarto`.

A rota de navegação é atualizada de `/room_details/:roomId` para `/room_details/:hotelId/:roomId` para que a tela tenha o `hotelId` necessário para as chamadas de API.

## Componentes Afetados

### Backend
- **Novo:** `quartoPublico.service.ts` (`src/services/`) — função `getRoomPublicDetails(hotelId, quartoId)` com join em `quarto + categoria_quarto + categoria_item + catalogo`
- **Novo:** `quartoPublico.controller.ts` (`src/controllers/`) — handler do novo endpoint público
- **Modificado:** `categoriaQuarto.routes.ts` — registrar rota pública `GET /:hotel_id/quartos/:quarto_id` (antes das rotas protegidas para evitar captura como parâmetro)

### Frontend
- **Modificado:** `room.dart` (`lib/features/rooms/domain/models/`) — adicionar campo `hotelId: String`
- **Novo:** `room_details_state.dart` (`lib/features/rooms/presentation/notifiers/`) — estado com `room`, `isLoading`, `hasError`
- **Novo:** `room_details_notifier.dart` (`lib/features/rooms/presentation/notifiers/`) — `Notifier<RoomDetailsState>` com `loadRoom(hotelId, quartoId)`
- **Modificado:** `room_details_page.dart` — converter para `ConsumerStatefulWidget`, substituir mock por dados reais, aplicar mudanças visuais (preço + carrossel abaixo da foto, cards de comodidade compactos, botão favoritar no lugar do chat)
- **Novo:** `availability_checker.dart` (`lib/features/rooms/presentation/widgets/`) — container com date pickers (check-in/check-out), botão "Verificar disponibilidade" e exibição do resultado como mensagem
- **Modificado:** `app_router.dart` (`lib/core/router/`) — rota `/room_details/:roomId` → `/room_details/:hotelId/:roomId`
- **Modificado:** `home_notifier.dart` — mapear campo `hotelId` do `RecommendedRoom` para o model `Room`
- **Modificado:** `room_card.dart` — receber `hotelId` como parâmetro; navegar para `/room_details/$hotelId/$roomId`
- **Modificado:** `home_page.dart` — passar `hotelId` para `RoomCard`

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| Novo endpoint `/:hotel_id/quartos/:quarto_id` em vez de `/:hotel_id/categorias/:id` | Navegação já usa `quarto_id` (home e busca retornam esse ID); aceitar o ID correto evita conversão dupla no frontend |
| Estado independente por seção (`room`, `availability`, `isFavorite`) | RF14: cada seção exibe loading/erro isolado sem bloquear as demais |
| `ConsumerStatefulWidget` para `RoomDetailsPage` | Date pickers precisam de `StatefulWidget`; acesso a providers exige `ConsumerWidget` |
| Rota `/room_details/:hotelId/:roomId` | `hotelId` é necessário para chamar endpoints `/:hotel_id/...`; já disponível no response da home |
| Ícones de comodidade mapeados por `categoria` do catálogo | A tabela `catalogo` tem campo `categoria` (ex: CONECTIVIDADE, CAMA) — usar como chave para selecionar `IconData` padronizado |

## Contratos de API

| Método | Rota | Auth | Body | Response |
|--------|------|------|------|----------|
| GET | `/api/hotel/:hotel_id/quartos/:quarto_id` | ❌ | — | `QuartoPublicoDetails` |
| GET | `/api/hotel/:hotel_id/disponibilidade?data_checkin=&data_checkout=` | ❌ | — | `CategoriaDisponibilidade[]` (já existe) |
| POST | `/api/usuarios/favoritos` | ✅ | `{ hotel_id, quarto_id }` | `{ success: true }` |
| DELETE | `/api/usuarios/favoritos/:hotel_id` | ✅ | — | `{ success: true }` |

### Shape de `QuartoPublicoDetails`
```json
{
  "quarto_id": 1,
  "numero": "101",
  "valor_diaria": "350.00",
  "hotel_id": "uuid",
  "nome_hotel": "Grand Hotel Budapest",
  "cidade": "Budapest",
  "uf": "HU",
  "categoria": {
    "id": 2,
    "nome": "Suíte Deluxe",
    "capacidade_pessoas": 2,
    "itens": [
      { "catalogo_id": 1, "nome": "Wi-Fi", "categoria": "CONECTIVIDADE", "quantidade": 1 },
      { "catalogo_id": 3, "nome": "Ar-condicionado", "categoria": "CLIMATIZACAO", "quantidade": 1 }
    ]
  }
}
```

## Modelos de Dados

Nenhuma tabela nova. A lógica consulta `quarto`, `categoria_quarto`, `categoria_item` e `catalogo` — todas já existentes.

Model Flutter atualizado:
```dart
Room {
  id: String              // quarto_id
  hotelId: String         // hotel_id (novo campo)
  title: String           // nome da categoria
  hotelName: String
  destination: String
  description: String     // preenchido com nome + número do quarto até campo de descrição ser adicionado ao schema
  imageUrls: List<String>
  rating: String
  amenities: List<Amenity>
  price: double
  host: Host
}
```

## Dependências

**Flutter:**
- [ ] `flutter_riverpod` — já em uso; `Notifier` para `RoomDetailsNotifier`
- [ ] `go_router` — já em uso; atualizar rota para incluir `hotelId`
- [ ] `intl` — formatar datas dos date pickers (verificar se já no pubspec)

**Backend:**
- [ ] `withTenant` + `masterPool` — padrão cross-tenant já implementado
- [ ] Endpoint de disponibilidade já existe em `categoriaQuarto.routes.ts` (sem alterações)

**Outras features:**
- [ ] P0 — autenticação base (token JWT necessário para endpoints de favoritos)
- [ ] P4-C — `hotel_details` como destino de navegação ao tocar em nome/foto/saiba mais do hotel

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| GET favoritos não implementado — estado inicial do botão desconhecido | Iniciar botão como não-favoritado; aceitar comportamento visual até endpoint GET ser criado |
| `hotelId` ausente em quartos vindos da busca | `searchRoom.service.ts` já retorna `hotel_id` — verificar mapeamento antes de integrar busca → room_details |
| Imagem real do quarto indisponível no endpoint público | Usar placeholder (asset local ou URL genérica) na exibição; URL real virá quando o schema de foto for mapeado no endpoint |
| Catálogo com `categoria` nula ou desconhecida | Fallback para ícone genérico (`Icons.hotel`) se a categoria não tiver mapeamento conhecido |
