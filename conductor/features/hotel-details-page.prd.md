# PRD — Hotel Details Page

## Contexto
A tela de detalhes do hotel (`hotel_details_page`) é um ponto central na jornada de reserva do usuário. Atualmente os dados exibidos são mockados, o que impede que o usuário tome decisões com base em informações reais do estabelecimento.

## Problema
A tela não busca dados reais da API, impedindo que o usuário conheça o hotel de forma completa — nome, descrição, fotos, avaliações de outros hóspedes e políticas — antes de avançar para a escolha de um quarto.

## Público-alvo
Usuários finais (autenticados ou não) que navegam até a página de detalhes de um hotel para conhecer o estabelecimento e decidir se querem fazer uma reserva.

## Requisitos Funcionais
1. Ao entrar na tela, buscar dados do hotel via `hotel_id` recebido por rota
2. Exibir nome, descrição e informações gerais do hotel
3. Exibir galeria de fotos de capa e perfil do hotel
4. Exibir avaliações dos hóspedes com nota média
5. Exibir comodidades do hotel (catálogo) — verificar durante implementação se já aparecem na tela; se não, adicionar
6. Exibir políticas do hotel via hipertexto, seguindo o padrão visual da aplicação
7. Exibir quartos disponíveis como cards diretamente na página, com filtro por número de camas
8. Exibir loading state (skeleton/loader) para cada seção enquanto os dados carregam
9. Tratar erros, incluindo hotel não encontrado (404)

## Requisitos Não-Funcionais
- [ ] Performance: resposta e renderização em menos de 2s por seção
- [ ] Segurança: endpoints públicos (sem auth) — fluxo de reserva pertence à `room_details_page`
- [ ] Acessibilidade: imagens com texto alternativo, contraste adequado
- [ ] Responsividade: funcionar em dispositivos móveis (iOS e Android)

## Critérios de Aceitação
- Dado que o usuário navega para `/hotel_details/:hotelId`, quando a tela carrega, então os dados do hotel (nome, descrição, fotos) são exibidos corretamente
- Dado que o hotel possui avaliações, quando a tela carrega, então a nota média e os comentários são exibidos
- Dado que o hotel possui quartos, quando a tela carrega, então todos os cards de quartos são exibidos sem filtro ativo por padrão
- Dado que o usuário seleciona um filtro de número de camas, quando aplicado, então apenas os quartos correspondentes são exibidos; ao desselecionar, todos voltam a aparecer
- Dado que o `hotelId` é inválido ou inexistente, quando a tela carrega, então uma mensagem de erro adequada é exibida
- Dado que os dados ainda estão carregando, quando a tela é exibida, então skeletons/loaders aparecem em cada seção

## Fora de Escopo
- Fluxo de reserva (pertence à `room_details_page`)
- Edição ou cadastro de informações do hotel
- Painel administrativo do hotel
- Notificações

## Endpoints Utilizados

| Método | Rota                              | Auth | Descrição             |
|--------|-----------------------------------|------|-----------------------|
| GET    | `/:hotel_id/catalogo`             | ❌   | Comodidades do hotel  |
| GET    | `/:hotel_id/categorias`           | ❌   | Tipos de quarto       |
| GET    | `/:hotel_id/configuracao`         | ❌   | Políticas do hotel    |
| GET    | `/hotel/:hotel_id/avaliacoes`     | ❌   | Avaliações do hotel   |
| GET    | `/uploads/hotels/:hotel_id/cover` | ❌   | Fotos de capa         |

## Dependências
- **Requer:** P0, P4-A ou P4-B (origem de navegação)
- **Bloqueia:** —
