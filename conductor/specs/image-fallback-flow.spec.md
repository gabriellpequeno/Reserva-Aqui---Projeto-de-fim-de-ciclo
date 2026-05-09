# Spec — Image Fallback Flow

## Referência
- **PRD:** [conductor/features/image-fallback-flow.prd.md](../features/image-fallback-flow.prd.md)

## Abordagem Técnica

Solução **100% frontend**, sem alterações no backend. O front passa a tratar inteligentemente o cenário em que o backend devolve URLs apontando para arquivos inexistentes (registros órfãos no BD) ou em que não há foto cadastrada.

A estratégia central é um widget reutilizável (`SmartNetworkImage`) que:

1. Recebe a URL candidata e o `fallbackUrl` (mock determinístico).
2. Faz um **HEAD request prévio** via Dio para validar a existência do recurso.
3. Se o HEAD retornar 2xx → carrega a imagem real via `Image.network`.
4. Se o HEAD retornar erro (404, timeout, etc.) ou a URL for vazia/null → mostra o mock direto, sem tentativa adicional.
5. `errorBuilder` continua presente como rede de segurança final.

Cada superfície (home, favoritos, hotel details, room details) escolhe seu mock baseado em regras específicas:
- **Quartos**: imagem fixa por tipo de quarto (`categoria.nome`), com fallback para imagem genérica de quarto.
- **Hotéis**: mock determinístico via `hashCode` do `hotelId`.

O backend continua intocado — pode seguir devolvendo URLs órfãs e isso é aceito como custo de manter o escopo restrito a frontend.

## Componentes Afetados

### Backend
- **Nenhum.** Backend permanece como está (inclusive os endpoints que retornam URLs para arquivos potencialmente inexistentes).

### Frontend
- **Novo:** `SmartNetworkImage` (`Frontend/lib/core/widgets/smart_network_image.dart`)
  - `ConsumerStatefulWidget` que faz HEAD pré-flight via `dioProvider`, alterna entre URL real e fallback.
  - No mesmo arquivo, expõe helpers puros: `fallbackForRoom(String? categoria)` e `fallbackForHotel(String hotelId)`.
  - Mantém duas listas const: `_hotelMocks` (lista de URLs Unsplash) e `_roomTypeMocks` (`Map<String, String>` de categoria → URL).
- **Modificado:** `room_card.dart` (`Frontend/lib/features/home/presentation/widgets/`)
  - Substitui `Image.network` direto por `SmartNetworkImage`, passando `imageUrl` e `fallbackForRoom(categoria)`.
- **Modificado:** `favorite_card.dart` (`Frontend/lib/features/favorites/presentation/widgets/`)
  - Reverte uso de `firstCoverFotoId` (já que backend não muda); usa `SmartNetworkImage` que resolve a primeira foto via `listHotelCovers` internamente, com `fallbackForHotel(hotelId)`.
- **Modificado:** `hotel_details_notifier.dart` + `hotel_details_page.dart`
  - Notifier continua chamando `listHotelCovers`; se vier vazio, page usa `SmartNetworkImage` com `fallbackForHotel(hotelId)` em cada slot do carrossel.
- **Modificado:** `room_details_notifier.dart` + `room_details_page.dart`
  - Notifier mantém `_parseImageUrls`; page substitui `NetworkImage` direto por `SmartNetworkImage` com `fallbackForRoom(categoria)`.

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|---------------|
| 100% frontend, sem tocar backend | Mantém escopo curto e desacoplado; equipes de outras áreas não são afetadas |
| Widget único `SmartNetworkImage` | Centraliza lógica de validação + fallback; evita duplicação em ~5 telas |
| HEAD request pré-flight | Confirma existência antes de gastar bandwidth com GET; evita 404 visual no `Image.network` |
| Imagem fixa por tipo de quarto | Hóspede não percebe variação aleatória entre quartos do mesmo tipo; visualmente coerente com a categoria |
| Hash determinístico por hotelId | Mesmo hotel sempre cai no mesmo mock; estabilidade visual entre renders sem persistir mapeamento |
| Lista de mocks compartilhada | Constantes `_hotelMocks` e `_roomTypeMocks` no mesmo arquivo do widget; uma fonte da verdade |
| `errorBuilder` como backstop | Mesmo com HEAD ok, eventual erro durante o GET (rede flaky) ainda cai em mock |

## Contratos de API

Nenhum endpoint é criado ou modificado. A feature **consome** os endpoints existentes:

| Método | Rota | Body | Response |
|--------|------|------|----------|
| GET | `/api/v1/uploads/hotels/:hotelId/cover` | — | `{ fotos: [{ id, orientacao, criado_em, url }] }` |
| GET | `/api/v1/uploads/hotels/:hotelId/cover/:fotoId` | — | binary (image/jpeg, image/png, image/webp) |
| GET | `/api/v1/uploads/hotels/:hotelId/rooms/:quartoId` | — | `{ fotos: [{ id, ordem, criado_em, url }] }` |
| GET | `/api/v1/uploads/hotels/:hotelId/rooms/:quartoId/:fotoId` | — | binary |
| HEAD | `/api/v1/uploads/hotels/:hotelId/cover/:fotoId` | — | 200 (existe) ou 404 (não existe) — usado pelo pré-flight |
| HEAD | `/api/v1/uploads/hotels/:hotelId/rooms/:quartoId/:fotoId` | — | 200 ou 404 — pré-flight |

> Observação: HEAD é suportado nativamente pelo Express para qualquer rota GET, então não exige nova implementação no backend.

## Modelos de Dados

Nenhum schema de banco é criado/alterado. As estruturas frontend novas são:

```
SmartNetworkImage (widget) {
  url: String?              // URL candidata vinda do backend (pode ser null/vazia)
  fallback: String          // URL de mock (Unsplash ou asset)
  width: double?
  height: double?
  fit: BoxFit?
}

_hotelMocks (const List<String>) {
  // ~6-8 URLs Unsplash de hotéis variados
}

_roomTypeMocks (const Map<String, String>) {
  'Suite':       'https://images.unsplash.com/...'
  'Standard':    'https://images.unsplash.com/...'
  'Deluxe':      'https://images.unsplash.com/...'
  'Family':      'https://images.unsplash.com/...'
  'Master':      'https://images.unsplash.com/...'
  '_default':    'https://images.unsplash.com/...'   // usado quando categoria não bate
}
```

## Dependências

**Bibliotecas:**
- [ ] `dio` — HTTP client já presente; usado para o HEAD pré-flight
- [ ] `flutter_riverpod` — já presente; necessário para acessar `dioProvider` dentro do widget

**Serviços externos:**
- [ ] `images.unsplash.com` — CDN das imagens de mock; sem autenticação, uso público

**Outras features:**
- [ ] Modelo `Room.categoria` (já existente em `rooms/domain/models/room.dart`) — `nome` é a chave do `_roomTypeMocks`
- [ ] `dioProvider` em `core/network/dio_client.dart` — fornece o cliente HTTP autenticado

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| HEAD request adiciona latência (cada imagem = 2 requests) | Cache local em memória dentro do widget: `Map<String, bool>` de URLs já validadas. Mesma URL na mesma sessão não dispara HEAD duas vezes |
| Categoria de quarto sem mapeamento (ex: "Suite Premium") | `fallbackForRoom` retorna `_roomTypeMocks['_default']` quando categoria não casar com nenhuma chave |
| Unsplash fora do ar (CDN externa) | Adicionar 1 asset local (`assets/mock_room.jpg`) como ultimate fallback se HEAD do mock também falhar; aceitar degradação gradual |
| Backend continua devolvendo URLs órfãs | Logs do servidor ficarão ruidosos com 404s/HEADs negativos. Aceito pelo escopo 100% frontend; ticket separado para sync de dados |
| Loop de fallback se mock também falhar | `errorBuilder` do `Image.network` do mock retorna um `Container` com cor sólida (`AppColors.primary` com alpha) — nunca tenta carregar outra URL |
| Race condition se URL muda durante HEAD | Widget cancela HEAD pendente em `didUpdateWidget` quando `widget.url` muda |
