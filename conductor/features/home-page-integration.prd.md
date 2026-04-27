# PRD — Home Page Integration

## Contexto
A home page possui dois slides verticais via PageView. O slide 1 é uma tela introdutória com imagem de fundo e botão "EXPLORAR". O slide 2 contém uma barra de busca estática e uma lista horizontal de `RoomCard`. Atualmente, nenhum dos dois elementos possui funcionalidade real: a barra de busca não responde ao toque e os cards exibem 4 hotéis hardcoded sem chamada de API.

## Problema
1. **Busca sem funcionalidade:** a barra de busca não permite ao usuário iniciar uma pesquisa nem aplicar filtros a partir da home.
2. **Recomendações estáticas:** a lista de quartos é mockada e não reflete o catálogo real, impedindo que o usuário descubra opções disponíveis ao abrir o app.

## Público-alvo
Usuários finais que abrem o app buscando um quarto para se hospedar — a home é a primeira tela com conteúdo real que encontram.

## Requisitos Funcionais
1. A barra de busca deve navegar para `search_page` com foco no campo de destino ao ser tocada
2. A barra de busca deve aceitar texto de busca por cidade, estado, bairro/região, nome de hotel, nome de quarto e tipo de acomodação
3. A barra de busca deve exibir um ícone de filtro ao final que, ao ser tocado, abre um dropdown com filtros de comodidade sem sair da home
4. Ao entrar no slide 2 da home, o app deve carregar automaticamente 5 quartos recomendados via API
5. A lista de recomendações deve seguir a lógica: melhores avaliados garantidos nas primeiras posições + sorteio aleatório para preencher slots restantes em caso de empate ou ausência de avaliações
6. Cada card deve exibir: nome do quarto, foto, nota média e comodidades
7. Tocar em um card deve navegar para `room_details` passando o `roomId` real
8. Durante o carregamento, exibir shimmer/placeholder nos cards
9. Em caso de erro na API, exibir mensagem discreta sem bloquear a tela
10. Em caso de lista vazia, exibir estado apropriado na área de cards

## Requisitos Não-Funcionais
- [ ] Performance: carregamento dos cards em menos de 2s em rede 4G
- [ ] Segurança: endpoint de recomendações não requer autenticação
- [ ] Responsividade: layout adaptado para diferentes tamanhos de tela mobile

## Lógica de Recomendação
```
1. Ordenar quartos por nota média DESC
2. Garantir os melhores avaliados nas primeiras posições
3. Slots restantes → sortear aleatoriamente do próximo bloco de nota
4. Se nenhum quarto tiver avaliação → retornar 5 quartos aleatórios do catálogo
```
> O sorteio garante variedade a cada abertura do app, demonstrando a amplitude do catálogo.

## Critérios de Aceitação
- Dado que o usuário está na home, quando tocar no campo de busca, então deve ser navegado para `search_page` com foco no campo de destino
- Dado que o usuário está na home, quando tocar no ícone de filtro, então deve abrir um dropdown com filtros de comodidade sem sair da tela
- Dado que o usuário entra no slide 2 da home, quando a tela montar, então deve disparar o carregamento dos 5 quartos recomendados
- Dado que a API retorna quartos, quando os dados chegarem, então os cards devem exibir nome, foto, nota e comodidades reais
- Dado que há empate de notas, quando os cards forem montados, então os melhores avaliados aparecem garantidos e os slots restantes são sorteados
- Dado que a API está indisponível, quando ocorrer erro, então uma mensagem discreta deve aparecer sem bloquear a tela
- Dado que os dados estão carregando, quando o slide 2 for exibido, então shimmer/placeholder deve aparecer nos cards

## Fora de Escopo
- Execução da busca diretamente na home (a home apenas redireciona para `search_page`)
- Filtros de preço e data na home
- Autenticação para visualizar recomendações
- Alteração estrutural no widget `RoomCard`

## Endpoints
| Método | Rota                                         | Auth | Descrição                           |
|--------|----------------------------------------------|------|-------------------------------------|
| GET    | `/quartos/busca?q=`                          | ❌   | Busca cross-tenant já existente     |
| GET    | `/quartos/recomendados` *(a criar — EXT-1)*  | ❌   | 5 quartos recomendados com fallback |
| GET    | `/uploads/hotels/:hotel_id/rooms/:quarto_id` | ❌   | Foto do quarto para o card          |

## Lacunas no Backend — `/quartos/busca`

O endpoint `/api/quartos/busca` já existe e cobre parte dos critérios de busca, mas apresenta as seguintes lacunas em relação ao RF-2:

| Critério             | Status no endpoint atual | O que falta                                                                 |
|----------------------|--------------------------|-----------------------------------------------------------------------------|
| Nome do hotel        | ✅ coberto               | —                                                                           |
| Cidade               | ✅ coberto               | —                                                                           |
| Estado (UF)          | ✅ coberto               | —                                                                           |
| Nome do quarto       | ❌ ausente               | Adicionar `numero ILIKE` e `descricao ILIKE` no fan-out dos tenants         |
| Tipo de acomodação   | ❌ ausente               | Adicionar filtro por `categoria_quarto_id` ou nome da categoria no fan-out  |
| Bairro/região        | ❌ ausente               | Campo não existe em `anfitriao` — requer migration ou campo de endereço     |
| Filtro comodidades   | ❌ ausente               | Endpoint só aceita `q` livre — requer novos query params estruturados       |

> Estas lacunas devem ser endereçadas como tasks de backend (**EXT-2**) antes de que o frontend passe esses critérios para a `search_page`.

## Dependências
- **EXT-1:** endpoint `/quartos/recomendados` deve ser criado no backend antes da integração dos cards
- **EXT-2:** ajustes no endpoint `/quartos/busca` para cobrir busca por nome de quarto, categoria, bairro e comodidades
- **P0:** autenticação base da aplicação
