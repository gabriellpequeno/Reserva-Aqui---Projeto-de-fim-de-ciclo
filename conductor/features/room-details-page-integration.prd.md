# PRD — Room Details Page Integration

## Contexto
A tela de detalhes do quarto (`/room_details/:roomId`) exibe atualmente dados mockados com o modelo `Room` local. O usuário não vê informações reais do quarto, não consegue navegar pelas fotos, verificar disponibilidade, favoritar nem avançar para reserva.

## Problema
A tela não reflete dados reais — preço, fotos, comodidades, descrição e disponibilidade são todos fictícios, impedindo o usuário de tomar uma decisão informada antes de reservar.

## Público-alvo
Usuários finais que chegam na tela via card da home ou resultado de busca e querem conhecer melhor um quarto antes de reservá-lo.

## Requisitos Funcionais
1. Ao entrar na tela com `:roomId`, buscar dados reais da categoria do quarto via API
2. Exibir galeria de fotos em carrossel navegável posicionado ao final da foto de capa
3. Exibir preço da diária na seção intermediária da tela (não sobreposto à foto)
4. Exibir comodidades com ícones padronizados por tipo em cards compactos
5. Label "Comodidades" posicionado próximo aos cards; cards no tamanho do ícone + texto em até 2 linhas
6. Exibir detalhes do quarto (capacidade, descrição)
7. Exibir descrição do hotel
8. Tocar no nome, foto ou "saiba mais" do hotel deve navegar para `hotel_details`
9. Exibir dados do anfitrião (nome, bio, avaliação)
10. Exibir container de verificação de disponibilidade abaixo das comodidades, com campos de check-in e check-out (date picker) e botão "Verificar disponibilidade" — resultado exibido como mensagem abaixo do botão
11. Botão de favoritar/desfavoritar posicionado onde está o ícone de chat atualmente
12. Favoritar requer autenticação — ação não autenticada redireciona para login
13. Botão "Reservar" navega para `checkout_page` passando o `roomId`
14. Loading e erros tratados de forma independente por seção da tela

## Requisitos Não-Funcionais
- [ ] Performance: dados do quarto carregados em menos de 2s em rede 4G
- [ ] Segurança: favoritar requer token válido — ações não autenticadas redirecionam para login
- [ ] Responsividade: layout adaptado para mobile e web

## Critérios de Aceitação
- Dado que o usuário entra na tela, quando os dados carregarem, então nome, preço, fotos, comodidades e descrição reais devem ser exibidos
- Dado que há fotos, quando a tela carregar, então o carrossel deve estar ao final da foto de capa e ser navegável
- Dado que o usuário toca no nome, foto ou "saiba mais" do hotel, então deve ser navegado para `hotel_details`
- Dado que o usuário seleciona datas e toca em "Verificar disponibilidade", então uma mensagem de disponível ou indisponível aparece abaixo do botão
- Dado que o usuário está autenticado, quando tocar no botão de favoritar, então o quarto é favoritado/desfavoritado com feedback visual
- Dado que o usuário não está autenticado, quando tocar em favoritar, então é redirecionado para login
- Dado que o usuário toca em "Reservar", então navega para `checkout_page` com `roomId`
- Dado que a API está indisponível, quando ocorrer erro, então cada seção exibe estado de erro independente sem bloquear a tela

## Fora de Escopo
- Fluxo de checkout (pertence à P5-C)
- Avaliações e reviews do quarto nesta tela
- Edição de dados pelo anfitrião

## Endpoints
| Método | Rota                                         | Auth | Descrição                    |
|--------|----------------------------------------------|------|------------------------------|
| GET    | `/:hotel_id/categorias/:id`                  | ❌   | Detalhes da categoria/quarto |
| GET    | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | ❌   | Fotos do quarto              |
| GET    | `/:hotel_id/disponibilidade`                 | ❌   | Verificar disponibilidade    |
| POST   | `/usuarios/favoritos`                        | ✅   | Adicionar favorito           |
| DELETE | `/usuarios/favoritos/:hotel_id`              | ✅   | Remover favorito             |

## Dependências
- **P0:** autenticação base da aplicação
- **P2-A:** favoritar requer usuário autenticado
- **P4-C:** `hotel_details` como origem de navegação para esta tela

## Bloqueia
- **P5-C:** `checkout_page` depende do `roomId` passado por esta tela
