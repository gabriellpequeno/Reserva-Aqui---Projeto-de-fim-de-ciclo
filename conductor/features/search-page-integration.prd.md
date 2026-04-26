# PRD — Search Page Integration (P4-B)

## Contexto

O aplicativo possui uma tela de busca de quartos em `lib/features/search/presentation/pages/search_page.dart`, com um header contendo três campos (destino, datas e hóspedes) e um botão de busca. Hoje, a tela exibe três resultados hardcoded retornados pelo `SearchNotifier` após um `Future.delayed(1s)`, usando `FavoriteCard` para renderizar em grid (web) ou lista (mobile). Os estados de `destination`, `guests`, `dateRange`, `results` e `isLoading` já estão definidos no notifier, e o campo de destino já está conectado via `updateDestination()`.

Esta feature integra a tela à API real, substituindo os dados mockados por resultados vindos do endpoint `GET /quartos/busca` (a ser criado via task EXT-1) e implementando os pickers de datas e hóspedes que estão com `onTap` vazio.

Branch: `feat/search-page-integration`

## Problema

A tela de busca não realiza chamadas reais à API: retorna sempre os mesmos três resultados mockados independentemente do termo pesquisado. Os campos de datas e hóspedes não possuem pickers funcionais — o campo de datas exibe um valor hardcoded (`14/04/26 - 15/04/26`) e o contador de hóspedes não reage ao toque. Isso impede que o usuário filtre ou encontre quartos reais, inviabilizando o fluxo principal de descoberta e reserva no aplicativo.

## Público-alvo

Usuários finais (autenticados ou não) que buscam quartos para reservar filtrando por cidade, intervalo de datas e número de hóspedes.

## Requisitos Funcionais

1. O usuário deve conseguir buscar quartos digitando a cidade do hotel, com sugestão e autocomplete de localidade enquanto digita
2. O usuário deve conseguir abrir um seletor de datas (date range picker) ao tocar no campo de datas e ter o intervalo escolhido exibido no formato `dd/MM/yy - dd/MM/yy`
3. O usuário deve conseguir abrir um seletor de hóspedes (bottom sheet ou dialog com contador) ao tocar no campo de hóspedes e ter o valor refletido no campo
4. O sistema deve chamar o endpoint `GET /quartos/busca?q=&checkin=&checkout=&hospedes=` ao submeter a busca, enviando apenas os parâmetros informados (datas e hóspedes são opcionais)
5. O sistema deve mapear a resposta da API para o modelo `FavoriteRoom` (`id`, `title`, `hotelName`, `destination`, `imageUrl`, `rating`, `amenities`, `price`) e exibir os resultados em grid (web) ou lista (mobile) usando `FavoriteCard`
6. O sistema deve buscar a imagem de cada quarto via `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`
7. O sistema deve manter os estados de loading e resultado vazio já implementados no `SearchNotifier`
8. Ao tocar em um card de resultado, o usuário deve ser navegado para `/room_details/:id`

## Requisitos Não-Funcionais

- [ ] Performance: resposta da busca renderizada em menos de 2s em rede 4G; debounce de 400ms no campo de destino caso busca automática seja habilitada
- [ ] Segurança: endpoint de busca é público (sem auth), mas o backend deve validar e sanitizar o parâmetro `q` para prevenir injeção e proteger contra requisições maliciosas
- [ ] Acessibilidade: campos do header com labels/semantics legíveis por leitores de tela; pickers (datas e hóspedes) navegáveis via teclado na web
- [ ] Responsividade: manter layout em grid no web e lista no mobile já implementado — comportamento consistente ao conectar à API real

## Critérios de Aceitação

- Dado que o usuário digitou uma cidade no campo de destino, quando tocar no botão de busca, então o sistema deve chamar `GET /quartos/busca?q={cidade}&...` e exibir os resultados em grid (web) ou lista (mobile)
- Dado que o usuário tocou no campo de datas, quando o date range picker abrir e ele selecionar um intervalo, então o campo deve exibir `dd/MM/yy - dd/MM/yy` e o estado `dateRange` no `SearchNotifier` deve ser atualizado
- Dado que o usuário tocou no campo de hóspedes, quando o bottom sheet/dialog abrir e ele ajustar o contador, então o valor selecionado deve ser refletido no campo e em `updateGuests()`
- Dado que a busca está em andamento, quando a resposta ainda não chegou, então a tela deve exibir o estado de loading já implementado no `SearchNotifier`
- Dado que a busca retornou uma lista vazia, quando o `SearchNotifier` receber a resposta, então a tela deve exibir o estado vazio já implementado
- Dado que o backend retorna quartos com `hotel_id` e `quarto_id`, quando o `FavoriteCard` renderizar, então a imagem deve ser carregada de `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`
- Dado que o usuário vê os resultados, quando tocar em um `FavoriteCard`, então deve ser navegado para `/room_details/:id`

## Fora de Escopo

- Filtro por disponibilidade real (datas e hóspedes são opcionais — refinam, não bloqueiam resultados)
- Filtros avançados além dos 3 campos do header (faixa de preço, avaliação, amenities, etc.)
- Autocomplete com API real de localidades (usa dados estáticos ou o próprio `/quartos/busca`)
- Histórico de buscas recentes ou sugestões personalizadas
- Paginação ou scroll infinito dos resultados
- Mapa com localização dos hotéis
- Criação do endpoint `GET /quartos/busca` no backend (task EXT-1 separada)

## Dependências

| Direção | Task | Motivo |
|---|---|---|
| Requer | EXT-1 — endpoint de busca | Backend precisa expor `GET /quartos/busca` antes da integração |
| Requer | P0 — infra HTTP client | Cliente HTTP para chamadas à API |
| Bloqueia | — | Folha |

## Endpoints

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| GET | `/quartos/busca` *(a criar — EXT-1)* | ❌ | Busca por nome do hotel / cidade / estado / quarto |
| GET | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | ❌ | Foto do quarto para o card |
