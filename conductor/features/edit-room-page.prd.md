# PRD — edit-room-page

## Contexto
O anfitrião cadastrado no Reserva Aqui precisa editar quartos já existentes no seu hotel. A tela `edit_room_page.dart` já existe como formulário estático sem integração com a API — carrega dados mock hardcoded de "Grand Hotel Budapest", o botão "Salvar" executa um delay fictício de 1 segundo e os campos de camas, banheiros e fotos não possuem correspondência real com o backend. A seção de comodidades não existe na tela atual.

## Problema
Sem integração, o anfitrião não consegue visualizar nem persistir alterações no quarto. O formulário atual exibe dados falsos, não pré-popula a partir do `roomId` recebido via rota, omite a gestão de comodidades e possui campos (camas, banheiros) sem correspondência na API. A tela precisa ser conectada ao backend para carregar, editar e salvar dados de categoria, comodidades e fotos de um quarto existente.

## Público-alvo
Anfitriões (hosts) autenticados que gerenciam quartos cadastrados no Reserva Aqui.

## Requisitos Funcionais
1. Ao entrar na tela, carregar dados reais do quarto via `GET /hotel/quartos/:id` (identificado pelo `roomId` da rota), buscar os dados da categoria vinculada via `GET /:hotel_id/categorias/:id` e as fotos existentes via `GET /uploads/hotels/:hotel_id/rooms/:quarto_id`.
2. Pré-popular o formulário com: nome da categoria, descrição, preço, capacidade e status (`disponivel`) do quarto físico.
3. Exibir as comodidades atuais da categoria como chips selecionados, carregando o catálogo completo via `GET /:hotel_id/catalogo` para permitir adicionar novas ou remover existentes.
4. Exibir as fotos existentes do quarto com opção de remover cada uma (`DELETE /uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id`).
5. Permitir adicionar novas fotos via galeria — submetidas ao salvar via `POST /uploads/hotels/:hotel_id/rooms/:quarto_id`.
6. Ao salvar, executar o fluxo encadeado:
   - `PATCH /hotel/categorias/:id` — atualizar nome, descrição, preço, capacidade
   - `POST /hotel/categorias/:id/itens` — para cada comodidade adicionada
   - `DELETE /hotel/categorias/:id/itens/:catalogo_id` — para cada comodidade removida
   - `PATCH /hotel/quartos/:id` — atualizar status (`disponivel`)
   - `DELETE /uploads/.../:foto_id` — para cada foto marcada para remoção
   - `POST /uploads/...` — para cada foto nova selecionada
7. Exibir indicador de progresso com a etapa atual durante o fluxo de salvamento.
8. Em caso de sucesso, voltar para `my_rooms_page` e disparar reload da lista.
9. Em caso de erro em qualquer etapa, exibir SnackBar com mensagem descritiva; formulário permanece aberto para nova tentativa.

## Requisitos Não-Funcionais
- [ ] Segurança: todos os endpoints de escrita exigem autenticação via JWT (`hotelGuard`)
- [ ] Responsividade: layout funcional em portrait e landscape no mobile
- [ ] Performance: upload e remoção de fotos de forma sequencial para evitar sobrecarga de memória

## Critérios de Aceitação
- Dado que o host está autenticado e navega para `/edit_room/:roomId`, quando a tela carrega, então os campos de nome, descrição, preço, capacidade e status são populados com os dados reais do quarto/categoria
- Dado que a tela carregou com sucesso, quando o host visualiza a seção de comodidades, então as comodidades atuais da categoria aparecem como chips selecionados e as disponíveis no catálogo como chips não selecionados
- Dado que a tela carregou com sucesso, quando o host visualiza a seção de fotos, então as fotos existentes são exibidas com botão de remoção individual
- Dado que o formulário está preenchido corretamente, quando o host toca em "Salvar Alterações", então o fluxo encadeado executa com indicador de progresso visível
- Dado que o fluxo de salvamento foi bem-sucedido, quando a tela fecha, então a lista em `my_rooms_page` reflete as alterações sem navegação manual
- Dado uma falha em qualquer etapa do salvamento, quando o erro ocorre, então um SnackBar exibe mensagem clara e o formulário permanece aberto
- Dado que o `roomId` não existe no backend, quando a tela tenta carregar, então um estado de erro é exibido com botão de voltar

## Fora de Escopo
- Edição do número da unidade física (`numero` do quarto)
- Criação de novos itens no catálogo de comodidades a partir desta tela
- Rollback automático de etapas parcialmente concluídas
- Upload de fotos para outras unidades da mesma categoria (apenas o quarto identificado pelo `roomId` da rota)
- Os campos "Camas" e "Banheiros" presentes no stub atual — não têm correspondência direta na API e serão removidos
