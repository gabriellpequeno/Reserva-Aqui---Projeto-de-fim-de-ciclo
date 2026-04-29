# Spec — Hotel Details Page

## Referência
- **PRD:** conductor/features/hotel-details-page.prd.md

## Abordagem Técnica
Criar `HotelDetailsNotifier` com `HotelDetailsState` seguindo o padrão Riverpod já estabelecido no projeto. Ao entrar na tela, disparar múltiplas chamadas em paralelo via `Future.wait` usando `dioProvider`, alimentando cada seção da `hotel_details_page` independentemente. Cada seção possui seu próprio estado de loading/error, evitando que a falha de um endpoint quebre as demais seções.

## Componentes Afetados

### Backend
- Nenhum — todos os endpoints já existem. Apenas consumo de APIs existentes.

### Frontend
- **Novo:** `HotelDetailsNotifier` (`lib/features/rooms/presentation/notifiers/hotel_details_notifier.dart`)
- **Novo:** `HotelDetailsState` (`lib/features/rooms/presentation/notifiers/hotel_details_state.dart`)
- **Novo:** `HotelModel` (`lib/features/rooms/domain/models/hotel.dart`)
- **Novo:** `AvaliacaoModel` (`lib/features/rooms/domain/models/avaliacao.dart`)
- **Novo:** `ComodidadeModel` (`lib/features/rooms/domain/models/comodidade.dart`)
- **Novo:** `PoliticasModel` (`lib/features/rooms/domain/models/politicas.dart`)
- **Novo:** `CategoriaModel` (`lib/features/rooms/domain/models/categoria.dart`)
- **Modificado:** `hotel_details_page.dart` — substituir dados mockados por `ref.watch(hotelDetailsNotifierProvider)`, adicionar seção de comodidades se ausente, implementar filtro de camas reativo

## Decisões de Arquitetura
| Decisão | Justificativa |
|---------|---------------|
| `Future.wait` para chamadas paralelas | Todas as seções carregam simultaneamente, sem bloquear uma na outra |
| Loading/error por seção independente | Falha em avaliações não quebra a exibição de fotos ou quartos |
| `HotelModel` separado de `Room` | Evita acoplamento entre entidade de quarto e dados do hotel |
| Tratar cada future individualmente | Evita falha completa do `Future.wait` caso um endpoint lance exceção |

## Contratos de API

| Método | Rota | Body | Response |
|--------|------|------|----------|
| GET | `/:hotel_id/catalogo` | — | `[{ id, nome, icone }]` |
| GET | `/:hotel_id/categorias` | — | `[{ id, nome, capacidade, preco }]` |
| GET | `/:hotel_id/configuracao` | — | `{ checkin, checkout, regras, politicas }` |
| GET | `/hotel/:hotel_id/avaliacoes` | — | `[{ id, nota, comentario, usuario }]` + nota média |
| GET | `/uploads/hotels/:hotel_id/cover` | — | URLs das fotos de capa e perfil |

> ⚠️ Verificar se `GET /hotel/:hotel_id` para dados básicos existe sem autenticação. Se não existir, abrir task EXT antes de iniciar implementação.

## Modelos de Dados

```
HotelModel {
  id: String
  nome: String
  descricao: String
  coverUrls: List<String>
  profileUrl: String
  notaMedia: double
  avaliacoes: List<AvaliacaoModel>
  comodidades: List<ComodidadeModel>
  politicas: PoliticasModel
  categorias: List<CategoriaModel>
}

AvaliacaoModel {
  id: String
  nota: double
  comentario: String
  nomeUsuario: String
}

ComodidadeModel {
  id: String
  nome: String
  icone: String
}

PoliticasModel {
  checkin: String
  checkout: String
  regras: List<String>
}

CategoriaModel {
  id: String
  nome: String
  capacidade: int
  preco: double
}
```

## Dependências

**Bibliotecas:**
- [x] `dio ^5.7.0` — cliente HTTP (já presente)
- [x] `flutter_riverpod ^3.3.1` — state management (já presente)
- [x] `go_router ^17.2.1` — navegação (já presente)

**Outras features:**
- [x] P0 — setup do `dioProvider` e autenticação base
- [x] P4-A ou P4-B — origem de navegação que passa o `hotelId`

## Riscos Técnicos
| Risco | Mitigação |
|-------|-----------|
| Endpoint de dados básicos do hotel pode não existir sem auth | Verificar durante implementação; se não existir, abrir task EXT |
| Comodidades podem não estar renderizadas na tela atual | Auditar `hotel_details_page.dart` antes de integrar; adicionar seção se ausente |
| `Future.wait` pode falhar completamente se um future lançar exceção | Tratar cada future individualmente com try/catch antes de compor o estado |
| Modelos de resposta da API podem divergir do schema definido | Validar response real com chamada manual antes de fixar os models |
