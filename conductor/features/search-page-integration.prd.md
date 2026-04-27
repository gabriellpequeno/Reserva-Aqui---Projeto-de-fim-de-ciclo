# PRD — Search Page Integration (P4-B)

## Contexto

O aplicativo possui uma tela de busca de quartos em `lib/features/search/presentation/pages/search_page.dart`, com um header contendo três campos (destino, datas e hóspedes) e um botão de busca, além de um ícone de filtro para comodidades. Hoje, a tela exibe três resultados hardcoded retornados pelo `SearchNotifier` após um `Future.delayed(1s)`, usando `FavoriteCard` para renderizar em grid (web) ou lista (mobile). Os estados de `destination`, `guests`, `dateRange`, `amenities`, `results` e `isLoading` já estão definidos no notifier, e o campo de destino já está conectado via `updateDestination()`.

Esta feature integra a tela ao backend real e elimina todo dado mockado. Hoje o endpoint `GET /api/quartos/busca` existe mas apenas o parâmetro `q` é efetivo — `checkin`, `checkout`, `hospedes` e `amenidades` são aceitos e silenciosamente ignorados. Esta feature **implementa os filtros reais** no backend (exclusão de reservas sobrepostas por data, capacidade via `categoria_quarto`, AND de amenidades via `itens_do_quarto`), **introduz a camada `data/` no feature `search`** (services de busca, avaliações e uploads) e **reescreve o `SearchNotifier`** para buscar, agregar rating por hotel (`/api/hotel/:id/avaliacoes` em paralelo), resolver imagem por quarto (`/api/uploads/...`) e popular o dropdown de comodidades a partir dos resultados correntes.

Branch: `feat/search-page-integration`

## Problema

A tela de busca não realiza chamadas reais à API: retorna sempre os mesmos três resultados mockados independentemente do termo pesquisado. Os campos de datas e hóspedes não possuem pickers funcionais — o campo de datas exibe um valor hardcoded (`14/04/26 - 15/04/26`) e o contador de hóspedes não reage ao toque. Isso impede que o usuário filtre ou encontre quartos reais, inviabilizando o fluxo principal de descoberta e reserva no aplicativo.

## Público-alvo

Usuários finais (autenticados ou não) que buscam quartos para reservar filtrando por cidade/nome do hotel, intervalo de datas, número de hóspedes e comodidades desejadas.

## Requisitos Funcionais

1. O usuário deve conseguir buscar quartos digitando a cidade ou nome do hotel em um campo de texto livre (autocomplete de localidades fica fora do escopo desta versão — não há endpoint no backend)
2. O usuário deve conseguir abrir um seletor de datas (date range picker) ao tocar no campo de datas e ter o intervalo escolhido exibido no formato `dd/MM/yy - dd/MM/yy`
3. O usuário deve conseguir abrir um seletor de hóspedes (bottom sheet ou dialog com contador) ao tocar no campo de hóspedes e ter o valor refletido no campo
4. O usuário deve conseguir abrir um dropdown de comodidades ao tocar no ícone de filtro (localizado à direita da barra de pesquisa) e selecionar uma ou mais comodidades para filtrar os resultados — a lista de comodidades disponíveis é derivada dinamicamente dos resultados da busca atual
5. O sistema deve chamar o endpoint `GET /api/quartos/busca?q=&checkin=&checkout=&hospedes=&amenidades=` ao submeter a busca, enviando apenas os parâmetros efetivamente preenchidos pelo usuário (datas, hóspedes e comodidades são opcionais)
6. O sistema deve exibir os resultados em grid (web) ou lista (mobile) com card de resultado próprio do feature de busca, contendo: número do quarto, nome do hotel, cidade/UF, preço da diária, comodidades reais (vindas da API) e — quando disponíveis — imagem do quarto e rating agregado do hotel
7. O sistema deve buscar a imagem de cada quarto via `GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id` (endpoint que retorna JSON com lista de fotos; usar a `url` da foto de menor `ordem`). Quartos sem foto recebem placeholder visual neutro, sem dado falso
8. O sistema deve calcular o rating exibido no card a partir de `GET /api/hotel/:hotel_id/avaliacoes` (média de `nota_total`) em chamadas paralelas, uma por hotel único dos resultados. Hotéis sem avaliações exibem "Sem avaliações" — nunca um valor hardcoded
9. O sistema deve manter estados de loading, lista vazia, erro e resultado populado no `SearchNotifier`
10. Ao tocar em um card de resultado, o usuário deve ser navegado para `/room_details/:roomId`

## Requisitos Não-Funcionais

- [ ] Performance: resposta da busca renderizada em menos de 2s em rede 4G, incluindo as chamadas paralelas de rating e foto; `LIMIT 20` no fan-out backend mantém o custo previsível
- [ ] Segurança: endpoint de busca é público (sem auth), e o backend deve validar e sanitizar **todos** os parâmetros: `q` (comprimento, escape de wildcards SQL `%`/`_`/`\`), `checkin`/`checkout` (formato ISO, coerência do intervalo, não retroativos), `hospedes` (inteiro positivo limitado), `amenidades` (CSV de inteiros, tamanho máximo). Queries usam prepared statements via `withTenant`
- [ ] Acessibilidade: campos do header com labels/semantics legíveis por leitores de tela; date range picker, bottom sheet de hóspedes e dropdown de comodidades navegáveis via teclado na web e com foco visível
- [ ] Responsividade: manter layout em grid no web e lista no mobile já implementado — comportamento consistente ao conectar à API real

## Critérios de Aceitação

- Dado que o usuário digitou uma cidade ou nome de hotel no campo de destino, quando tocar no botão de busca, então o sistema deve chamar `GET /api/quartos/busca?q={valor}` (com demais params se preenchidos) e exibir os resultados em grid (web) ou lista (mobile)
- Dado que o usuário tocou no campo de datas, quando o date range picker abrir e ele selecionar um intervalo, então o campo deve exibir `dd/MM/yy - dd/MM/yy` e o estado `dateRange` no `SearchNotifier` deve ser atualizado
- Dado que o usuário tocou no campo de hóspedes, quando o bottom sheet/dialog abrir e ele ajustar o contador, então o valor selecionado deve ser refletido no campo e em `updateGuests()`
- Dado que o usuário tocou no ícone de filtro (lado direito da barra de pesquisa), quando o dropdown de comodidades abrir, então ele deve exibir a lista de comodidades derivada dos `itens[]` dos resultados correntes com checkboxes (sem duplicatas, agrupadas por categoria)
- Dado que ainda não houve busca, quando o usuário tocar no ícone de filtro de comodidades, então o dropdown deve mostrar a mensagem "Faça uma busca para filtrar por comodidades"
- Dado que o usuário selecionou uma ou mais comodidades no dropdown, quando confirmar a seleção, então o estado `selectedAmenityIds` no `SearchNotifier` deve ser atualizado, o dropdown deve fechar e uma nova busca deve ser disparada
- Dado que o usuário submeter a busca com datas, hóspedes ou comodidades selecionados, quando o sistema chamar a API, então deve incluir apenas os parâmetros efetivamente preenchidos (params não preenchidos são omitidos)
- Dado que o usuário submeter a busca com datas selecionadas, quando o backend processar, então quartos com reservas ativas (`SOLICITADA`, `AGUARDANDO_PAGAMENTO`, `APROVADA`) sobrepostas ao intervalo devem ser excluídos dos resultados
- Dado que o usuário submeter a busca com `hospedes`, quando o backend processar, então apenas quartos cuja categoria tenha `capacidade_pessoas >= hospedes` devem ser retornados
- Dado que o usuário submeter a busca com múltiplas comodidades, quando o backend processar, então apenas quartos que possuem TODAS as comodidades selecionadas devem ser retornados
- Dado que a busca está em andamento, quando a resposta ainda não chegou, então a tela deve exibir o estado de loading
- Dado que a busca retornou uma lista vazia, quando o `SearchNotifier` receber a resposta, então a tela deve exibir o estado vazio com mensagem adequada (diferenciada se há filtros ativos ou não)
- Dado que a busca retornou quartos, quando os cards renderizarem, então a imagem de cada quarto deve ser carregada via `GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id` (primeira foto por `ordem`); quartos sem foto devem exibir placeholder visual neutro
- Dado que a busca retornou quartos, quando os cards renderizarem, então o rating exibido deve ser a média de `nota_total` das avaliações do hotel (chamada paralela a `/api/hotel/:hotel_id/avaliacoes`); hotéis sem avaliações devem exibir "Sem avaliações"
- Dado que o usuário vê os resultados, quando tocar em um card, então deve ser navegado para `/room_details/:roomId`

## Fora de Escopo

- Autocomplete de localidades (backend não possui endpoint de cidades; campo de destino é texto livre nesta versão)
- Filtros avançados além de datas/hóspedes/comodidades (faixa de preço, avaliação mínima, etc.)
- Histórico de buscas recentes ou sugestões personalizadas
- Paginação ou scroll infinito dos resultados (backend limita a 20 hotéis por query)
- Mapa com localização dos hotéis
- Rating agregado por quarto (backend só modela avaliações por reserva, agregadas por hotel)
- Endpoint global de comodidades (`/api/comodidades`) — dropdown deriva dos resultados

## Dependências

| Direção | Task | Motivo |
|---|---|---|
| ✅ Concluída | Endpoint `GET /api/quartos/busca` (versão inicial) | Backend já expõe busca cross-tenant por `q`; filtros `checkin`/`checkout`/`hospedes`/`amenidades` ainda aceitos-mas-ignorados — **esta feature os implementa de verdade** |
| ✅ Concluída | Endpoint `GET /api/hotel/:hotel_id/avaliacoes` | Usado para calcular rating agregado por hotel |
| ✅ Concluída | Endpoint `GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id` | Retorna metadados das fotos do quarto (JSON com `fotos[]`) |
| ✅ Concluída | Rota `/room_details/:roomId` no `app_router.dart` | Destino da navegação ao tocar em um card |
| Requer | Alinhar `baseUrl` do Dio com `API_PREFIX` do backend | `dio_client.dart:6` usa `/api/v1`; backend monta em `/api` — conferir e ajustar antes da integração |
| Bloqueia | — | Folha |

## Endpoints

| Método | Rota | Auth | Descrição | Query Params |
|---|---|---|---|---|
| GET | `/api/quartos/busca` | ❌ | Busca cross-tenant por nome do hotel / cidade / UF / número do quarto, com filtros reais | `q` (obrigatório, 2–255 chars), `checkin`+`checkout` (ISO `YYYY-MM-DD`, opcionais em par), `hospedes` (int 1–20, opcional), `amenidades` (CSV de `catalogo_id`, AND lógico, opcional) |
| GET | `/api/hotel/:hotel_id/avaliacoes` ✅ | ❌ | Lista avaliações públicas do hotel; usado para calcular rating agregado | — |
| GET | `/api/uploads/hotels/:hotel_id/rooms/:quarto_id` ✅ | ❌ | Retorna JSON `{ fotos: [{ id, ordem, url, criado_em }] }` com metadados das fotos; `fotos[]` vazio indica quarto sem imagem | — |
| GET | `/api/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id` ✅ | ❌ | Serve o binário da foto (JPEG/PNG/WebP) — usado direto em `Image.network(url)` | — |

### Detalhes do Endpoint GET /api/quartos/busca

**Resposta (200 OK):**
```json
[
  {
    "quarto_id": number,
    "hotel_id": string,
    "numero": string,
    "descricao": string | null,
    "valor_diaria": string,
    "itens": [
      {
        "catalogo_id": number,
        "nome": string,
        "categoria": string,
        "quantidade": number
      }
    ],
    "nome_hotel": string,
    "cidade": string,
    "uf": string
  }
]
```

**Implementação:**
- Busca cross-tenant com limitação a 20 hotéis por query (fan-out via `withTenant`)
- `unaccent()` em `nome_hotel`, `cidade` e `uf`; escape de wildcards SQL (`%`, `_`, `\`) em `q`
- Filtro de disponibilidade quando `checkin`+`checkout` presentes: exclui quartos com reservas de status `SOLICITADA`, `AGUARDANDO_PAGAMENTO` ou `APROVADA` cujo intervalo se sobreponha ao solicitado (`r.data_checkin < $checkout AND r.data_checkout > $checkin`)
- Filtro de capacidade quando `hospedes` presente: JOIN com `categoria_quarto` e `cq.capacidade_pessoas >= $hospedes`
- Filtro de amenidades quando `amenidades` presente: AND lógico via `itens_do_quarto` (`HAVING COUNT(DISTINCT catalogo_id) = <tamanho_do_array>`)
- Considera apenas entidades ativas: `deleted_at IS NULL` em `quarto`, `categoria_quarto` e `catalogo`
- Retorna lista vazia se nenhum resultado encontrado
- Erros em tenants individuais não afetam outros resultados (fan-out tolerante)
- Códigos: 200 (sucesso), 400 (parâmetro inválido, uma mensagem específica por campo), 500 (erro servidor)
