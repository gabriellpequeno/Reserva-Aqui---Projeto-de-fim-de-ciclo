# PRD — my-rooms-page

## Contexto

A tela `my_rooms_page` (`lib/features/rooms/presentation/pages/my_rooms_page.dart`) é o painel do anfitrião (host) para gerenciar o inventário de quartos do seu hotel. Hoje a tela existe apenas com dados mockados, sem integração com o backend.

Esta feature integra a tela ao backend, habilitando listagem real, remoção parcial de unidades e inserção manual de reservas na agenda (reserva "cega", sem geração de ticket). A tela também serve como porta de entrada para os fluxos `add_room_page` (P5-A) e `edit_room_page` (P5-B).

**Ponto crítico de modelagem:** no backend, cada `Quarto` representa **uma unidade física** com `numero` único. O que agrupa "3 suítes master single" é o campo `categoria_quarto_id` (tipo de quarto). Portanto, a agregação em cards por tipo de quarto é **responsabilidade do frontend** — o `MyRoomsNotifier` deve agrupar a lista de `Quarto` por `categoria_quarto_id` e renderizar 1 card por categoria, com a contagem total de unidades.

## Problema

Hosts precisam gerenciar o inventário de tipos de quartos cadastrados no hotel. A tela deve permitir:
- Visualizar os tipos de quarto agregados (cada card representa N unidades de uma mesma categoria)
- Acessar a tela de edição de cada tipo
- Remover unidades parciais ou totais com dupla confirmação (modal + picker de quantidade)
- Inserir reservas manualmente na agenda, sem emissão de ticket, assumindo que o hotel possui sistema próprio de gestão interna e precisa lidar com reservas originadas fora do app

A capacidade diária é limitada pelo total de unidades de cada categoria: quando todas as unidades de um tipo estão ocupadas em um dia, esse dia deve aparecer **indisponível** tanto no fluxo do usuário final (`room_details`) quanto no calendário de reserva manual do host. Um dia só é considerado "cheio" se todas as unidades da categoria estão reservadas **naquele dia específico** (sobreposições parciais em datas diferentes não bloqueiam o calendário como um todo).

## Público-alvo

Anfitriões (hosts) autenticados que possuem hotel cadastrado na plataforma e precisam gerenciar o inventário de tipos de quartos, incluindo edição, remoção parcial de unidades e inserção manual de reservas na agenda.

## Requisitos Funcionais

1. Ao abrir a tela, o sistema deve listar todos os quartos do hotel autenticado via `GET /hotel/quartos` e agrupá-los por `categoria_quarto_id` no frontend, exibindo 1 card por categoria.
2. O sistema deve buscar as categorias via `GET /hotel/categorias` para enriquecer cada card com o nome e a descrição da categoria.
3. Cada card agregado deve exibir: foto (primeira unidade da categoria), nome da categoria, total de unidades, valor base/médio da diária e descrição resumida.
4. Para cada categoria, o sistema deve carregar a foto via `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`, usando o `quarto_id` de uma das unidades daquela categoria.
5. O `MyRoomsNotifier` (Riverpod) deve gerenciar: lista agregada por categoria, loading state, error state e método de refresh (pull-to-refresh).
6. O fluxo de deletar deve ser: botão "deletar" no card → modal de confirmação "tem certeza?" → seletor de quantidade (min 1, max = total de unidades da categoria) → ao confirmar, frontend dispara **N chamadas** `DELETE /hotel/quartos/:id`, uma para cada unidade escolhida. Se a quantidade escolhida for igual ao total, o tipo de quarto é removido por completo da listagem.
7. O fluxo de deletar deve tratar falhas parciais: se algumas chamadas `DELETE` falharem, exibir mensagem informando quantas unidades foram removidas e quantas permaneceram, e recarregar a lista.
8. O fluxo de reserva manual deve ser: botão "reserva manual" no card → abrir calendário com dias marcados como indisponíveis (aqueles em que todas as unidades da categoria estão ocupadas) → host seleciona intervalo de datas → confirma → sistema chama `POST /hotel/reservas` com `canal_origem: "manual"`, `tipo_quarto`, `num_hospedes`, `data_checkin`, `data_checkout` e `valor_total`.
9. A disponibilidade por dia deve ser computada no frontend a partir de `GET /hotel/reservas` (filtrado por categoria ou por quarto_ids da categoria) e do total de unidades cadastradas, comparando reservas sobrepostas dia a dia.
10. O usuário deve poder navegar para `edit_room_page` (P5-B) ao tocar em "editar" em um card.
11. O usuário deve poder navegar para `add_room_page` (P5-A) através de um FAB ou botão global de adicionar.
12. A tela deve exibir um estado vazio amigável quando o hotel não possuir quartos cadastrados, com CTA para adicionar o primeiro tipo de quarto.
13. A tela deve oferecer **busca local** por nome da categoria (filtra a lista já carregada, sem nova chamada ao backend).
14. A tela deve oferecer **filtro por categoria** usando as categorias retornadas em `GET /hotel/categorias` (chips ou dropdown).

## Requisitos Não-Funcionais

- [ ] **Performance:** listagem inicial exibida em menos de 2s após o `hotelId` estar disponível no estado global.
- [ ] **Segurança:** todas as rotas autenticadas devem enviar o token JWT do host; o backend já aplica `hotelGuard` em `/hotel/quartos` e `/hotel/reservas`.
- [ ] **Acessibilidade:** botões de editar, deletar e reservar com `semanticLabel` para leitores de tela; estados (loading, erro, vazio) devem ser anunciáveis.
- [ ] **Responsividade:** layout deve funcionar em diferentes tamanhos de tela mobile (portrait e landscape).
- [ ] **Gerenciamento de estado:** uso de Riverpod (`MyRoomsNotifier`) para lista agregada, loading, error e refresh, desacoplado da camada de UI.
- [ ] **Resiliência:** tratar falhas de rede em todas as chamadas com mensagens claras e opção de retry.
- [ ] **Consistência de estado após delete parcial:** em caso de falhas parciais nas N chamadas `DELETE`, a UI deve refletir o estado real (recarregando via `GET /hotel/quartos`) e comunicar quantas unidades foram efetivamente removidas.

## Critérios de Aceitação

- Dado que o host está autenticado e possui `hotel_id` carregado, quando abrir a `my_rooms_page`, então a lista de tipos de quartos do seu hotel deve ser exibida agregada por categoria.
- Dado que o hotel não possui quartos cadastrados, quando a tela carregar, então deve ser exibido um estado vazio com CTA para adicionar o primeiro quarto.
- Dado que o host tocou em "deletar" em um card, quando confirmar no modal e escolher uma quantidade menor que o total, então apenas N unidades devem ser removidas e o card deve continuar visível com `total - N` unidades.
- Dado que o host tocou em "deletar" e escolheu o valor máximo (igual ao total de unidades), quando confirmar, então todas as unidades devem ser removidas e o card deve sumir da listagem.
- Dado que o host tocou em "deletar" e cancelou o modal ou o picker, quando fechar, então nenhuma requisição `DELETE` deve ser disparada.
- Dado que ocorreu falha em parte das N chamadas `DELETE`, quando o fluxo terminar, então a UI deve exibir mensagem indicando quantas unidades foram removidas com sucesso e quantas falharam, e recarregar a lista.
- Dado que o host tocou em "reserva manual" em um card, quando o calendário abrir, então os dias em que todas as unidades daquela categoria estão ocupadas devem aparecer indisponíveis.
- Dado que o host selecionou um intervalo válido no calendário de reserva manual, quando confirmar, então a reserva deve ser registrada via `POST /hotel/reservas` com `canal_origem: "manual"` e o intervalo deve passar a bloquear o calendário em chamadas subsequentes.
- Dado que uma categoria tem 3 unidades e todas estão reservadas em um dia X, quando o usuário final abrir `room_details` e testar disponibilidade para o dia X, então deve receber "indisponível" com a data de próxima disponibilidade.
- Dado que uma categoria tem 3 unidades, 2 reservadas de 23/04 a 29/04 e 3 reservadas de 29/04 a 31/04, quando o calendário de reserva manual for aberto, então **apenas o dia 29/04** deve aparecer indisponível (dia em que todas as 3 unidades estão simultaneamente ocupadas).
- Dado que o host tocou em "editar" em um card, quando a ação for executada, então deve navegar para `edit_room_page` com a categoria/quartos selecionados.
- Dado que o host tocou no FAB global de adicionar, quando a ação for executada, então deve navegar para `add_room_page`.
- Dado que a requisição `GET /hotel/quartos` falhar, quando a tela carregar, então deve ser exibida mensagem de erro com botão "tentar novamente".
- Dado que o host puxou a tela para baixo, quando o refresh for disparado, então a lista deve ser recarregada do backend.
- Dado que o host digitou texto na busca, quando houver correspondência parcial com o nome de alguma categoria, então apenas os cards correspondentes devem permanecer visíveis.
- Dado que o host selecionou uma categoria no filtro, quando a seleção for aplicada, então apenas os cards daquela categoria devem permanecer visíveis.

## Dependências de Backend

Para que o fluxo de reserva manual funcione como "reserva cega" (sem identificação de hóspede), é necessário o seguinte ajuste no backend:

- [ ] **Ajustar `Reserva.validateWalkin`** (`Backend/src/entities/Reserva.ts`) para aceitar `canal_origem: "manual"` dispensando os campos de identificação do hóspede (`user_id`, `nome_hospede`, `cpf_hospede`, `telefone_contato`). Reservas marcadas como manuais servem apenas para bloquear a agenda, pois o hotel possui sistema próprio de gestão interna.

**Backlog técnico futuro (não bloqueia esta feature):**
- [ ] Criar endpoint `GET /hotel/categorias/:id/disponibilidade?from=X&to=Y` que retorne dias lotados por categoria, evitando o processamento pesado no frontend em hotéis com muitas reservas.
- [ ] Avaliar endpoint de remoção em lote `DELETE /hotel/categorias/:cat_id/quartos?quantidade=N` caso a estratégia de N chamadas revele problemas de consistência em produção.

## Fora de Escopo

- Implementação das telas `add_room_page` (P5-A) e `edit_room_page` (P5-B).
- Upload, alteração ou remoção de fotos dos quartos nesta tela.
- Geração de ticket ou comprovante de reserva — a reserva manual apenas altera a agenda.
- Seleção de unidade específica dentro da categoria ao criar reserva manual (o gerenciamento interno de "qual unidade vai para qual hóspede" é responsabilidade do sistema interno do hotel).
- Preenchimento de dados de hóspede na reserva manual (reserva cega).
- Relatórios de ocupação, analytics ou dashboards.
- Filtros avançados (faixa de preço, comodidades, datas). Apenas busca por nome e filtro por categoria.
- Endpoint dedicado de disponibilidade (vai para backlog técnico).
- Reordenação manual dos cards.
