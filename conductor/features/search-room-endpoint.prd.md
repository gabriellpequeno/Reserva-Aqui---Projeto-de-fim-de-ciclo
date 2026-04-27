# PRD — Search Room Endpoint (EXT-1)

## Contexto

O aplicativo possui uma tela de busca de quartos (feature P4-B — `search-page-integration`) que hoje exibe três resultados hardcoded renderizados pelo `SearchNotifier` após um `Future.delayed(1s)`. A integração com a API real está bloqueada porque o backend não expõe nenhuma rota pública de busca de quartos: a única rota existente para quartos é `GET /api/hotel/quartos`, protegida por `hotelGuard` e voltada ao gerenciamento interno do hotel anfitrião.

O backend segue uma arquitetura multi-tenant com schema-por-hotel: a tabela `anfitriao` vive na master DB (contém `nome_hotel`, `cidade`, `uf`, `schema_name`), enquanto a tabela `quarto` de cada hotel vive no seu próprio schema Postgres, acessada via `withTenant(schemaName, callback)` (`Backend/src/database/schemaWrapper.ts`). Não é possível, portanto, consultar quartos cross-tenant em uma única query — é obrigatório descobrir hotéis na master e federar a leitura dos quartos em memória.

Esta feature cria o endpoint `GET /api/quartos/busca` que a tela de busca consumirá para substituir os dados mockados.

Branch: `feat/search-page-integration` (compartilhada com P4-B) ou branch dedicada `feat/search-room-endpoint` — a definir no momento da implementação.

## Problema

A tela de busca de quartos (P4-B) não tem endpoint real para consumir. Hoje o frontend exibe dados mockados porque o backend só expõe `GET /api/hotel/quartos` sob `hotelGuard` (gerenciamento interno do hotel), sem nenhuma rota pública que permita ao hóspede pesquisar quartos entre hotéis filtrando por nome do hotel, cidade ou estado. Sem isso, o fluxo principal de descoberta e reserva do app fica inviável.

## Público-alvo

Consumido indiretamente por usuários finais (autenticados ou não) via a tela de busca do app. Público direto: time de frontend que precisa integrar `SearchNotifier` à API real.

## Requisitos Funcionais

1. O sistema deve expor `GET /api/quartos/busca` como rota pública (sem `hotelGuard` nem auth de usuário).
2. O endpoint deve aceitar o parâmetro `q` (string) e buscar hotéis cujo `nome_hotel`, `cidade` ou `uf` contenham o termo (case-insensitive, acento-insensitive via `unaccent` + `ILIKE`).
3. O endpoint deve aceitar os parâmetros opcionais `checkin` (ISO date), `checkout` (ISO date) e `hospedes` (inteiro) — tratados como refino, sem filtrar por disponibilidade real de reservas.
4. O sistema deve consultar a master DB (tabela `anfitriao`, filtrando `ativo = TRUE`) para descobrir hotéis que casam com `q`, limitando a no máximo 20 hotéis ordenados por relevância/proximidade do match.
5. Para cada hotel encontrado, o sistema deve iterar os schemas tenant via `withTenant()` em paralelo (`Promise.all`), agregando os quartos não deletados (`deleted_at IS NULL`) com seus itens e preço efetivo (reutilizando a query `SELECT_QUARTO_COM_ITENS` de `Backend/src/services/quarto.service.ts`).
6. O sistema deve retornar uma lista flat de quartos, cada item contendo: `quarto_id`, `hotel_id`, `numero`, `descricao`, `valor_diaria`, `itens[]`, `nome_hotel`, `cidade`, `uf` (os campos do hotel enriquecidos em memória a partir dos dados já lidos da master).
7. O sistema deve sanitizar o parâmetro `q` escapando os wildcards `%`, `_` e `\` antes de compor o padrão ILIKE, prevenindo wildcard injection.
8. O sistema deve retornar `400 Bad Request` se `q` for vazio/ausente, ou `200` com lista vazia se nenhum hotel casar.

## Requisitos Não-Funcionais

- [ ] Performance: p95 abaixo de 500ms para `q` casando até 20 hotéis; fan-out paralelo nos schemas tenant (`Promise.all`), não sequencial.
- [ ] Segurança: rota pública, mas com sanitização estrita de `q` (escape de wildcards + parametrização SQL); limite máximo de 20 hotéis por query para evitar fan-out abusivo.
- [ ] Observabilidade: logar tempo total da busca e número de hotéis iterados (para diagnosticar gargalos de pool no futuro).
- [ ] Escalabilidade: documentar como dívida técnica a troca de `ILIKE '%q%'` por `pg_trgm`/GIN quando o volume de hotéis crescer.

## Critérios de Aceitação

- Dado que o usuário envia `GET /api/quartos/busca?q=salvador`, quando houver hotéis ativos com `cidade ILIKE '%salvador%'`, então o endpoint deve responder `200` com um array de quartos contendo `quarto_id`, `hotel_id`, `nome_hotel`, `cidade`, `uf`, `valor_diaria`, `descricao`, `itens[]`.
- Dado que `q` está vazio ou ausente, quando a requisição chegar, então o endpoint deve responder `400` com mensagem `"Parâmetro q é obrigatório"`.
- Dado que `q="São Paulo"` com acento e outro hotel cadastrado como `cidade="Sao Paulo"` sem acento, quando a busca for feita, então ambos devem aparecer no resultado (acento-insensitive).
- Dado que `q` contém caracteres `%` ou `_`, quando a busca for feita, então estes caracteres devem ser tratados como literais (não como wildcards) e a query não deve retornar resultados espúrios.
- Dado que um hotel está com `ativo = FALSE`, quando houver match em `nome_hotel`, então seus quartos não devem aparecer.
- Dado que um quarto tem `deleted_at IS NOT NULL`, quando o hotel casar, então esse quarto deve ser excluído do resultado.
- Dado que 15 hotéis ativos casam com `q`, quando a busca rodar, então os 15 schemas tenant devem ser consultados em paralelo e a resposta agregada.
- Dado que nenhum hotel casa, quando a busca rodar, então o endpoint deve responder `200` com `[]`.

## Fora de Escopo

- Filtro real por disponibilidade de datas (consulta à tabela `reserva` de cada tenant).
- Aplicação real do parâmetro `hospedes` (requer coluna `capacidade` em `quarto` ou `categoria_quarto` — a ser confirmado/adicionado em task separada).
- Cálculo de preço total pela quantidade de diárias a partir de `checkin`/`checkout`.
- Retorno do campo `rating` (avaliação) — fica para EXT-2; endpoint devolve apenas os campos já existentes.
- Busca por `numero` de quarto, nome de `categoria_quarto` ou `descricao` do quarto (o requisito do PRD da tela fala em "busca por quarto", mas limitamos a `nome_hotel`/`cidade`/`uf` neste MVP).
- Substituição de `ILIKE '%q%'` por `pg_trgm`/full-text search (dívida técnica registrada).
- Paginação ou scroll infinito — resposta é lista única limitada a 20 hotéis.
- Autocomplete de localidades em endpoint separado.
- Retorno da URL da foto — o frontend monta via `GET /uploads/hotels/:hotel_id/rooms/:quarto_id` (já existe).
