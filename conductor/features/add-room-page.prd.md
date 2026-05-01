# PRD — add-room-page

## Contexto
O anfitrião cadastrado no Reserva Aqui precisa adicionar quartos ao seu hotel. A tela `add_room_page.dart` já existe como formulário estático sem integração com a API — submeter o formulário apenas exibe um SnackBar mock e fecha a tela sem persistir nada no backend.

## Problema
Sem integração, o anfitrião não consegue adicionar quartos reais ao hotel. O formulário atual tem problemas adicionais: comodidades são um dropdown de seleção simples com valores hardcoded (não vêm do catálogo real), o campo de valor é um dropdown de preços fixos (não aceita valor livre) e a capacidade é uma string em vez de número inteiro. A tela precisa ser conectada ao backend para persistir categorias, quartos e fotos.

## Público-alvo
Anfitriões (hosts) autenticados que gerenciam pousadas/hotéis cadastrados no Reserva Aqui.

## Requisitos Funcionais
1. Ao carregar a tela, buscar o catálogo de comodidades disponíveis do hotel via `GET /:hotel_id/catalogo` para popular um seletor de comodidades dinâmico.
2. O formulário deve permitir selecionar **múltiplas** comodidades (chips ou checkboxes — não um dropdown de seleção única).
3. O campo "Valor da Diária" deve aceitar entrada numérica decimal livre (não um dropdown de valores fixos).
4. O campo "Capacidade" deve ser um stepper numérico inteiro, compatível com o campo `capacidade_pessoas` da API.
5. Ao submeter o formulário, executar o fluxo encadeado:
   1. `POST /hotel/categorias` → obter `categoria_id`
   2. Para cada comodidade selecionada: `POST /hotel/categorias/:id/itens`
   3. Para cada unidade (1..N): `POST /hotel/quartos` → obter `quarto_id`
   4. Para cada foto selecionada: `POST /uploads/hotels/:hotel_id/rooms/:primeiro_quarto_id`
6. Exibir indicador de progresso com a etapa atual durante o fluxo de submissão.
7. Em caso de sucesso, pop para `my_rooms_page` e disparar reload da lista.
8. Em caso de erro em qualquer etapa, exibir SnackBar com mensagem descritiva (não bloquear a tela).

## Requisitos Não-Funcionais
- [ ] Segurança: todos os endpoints de escrita exigem autenticação via JWT (`hotelGuard`)
- [ ] Responsividade: layout funcional em portrait e landscape no mobile
- [ ] Performance: upload de fotos feito sequencialmente (uma por vez) para evitar sobrecarga de memória

## Critérios de Aceitação
- Dado que o host está autenticado, quando a tela carrega, então as comodidades do catálogo do hotel aparecem como opções selecionáveis
- Dado que o formulário está preenchido corretamente (nome, capacidade, valor, ao menos 1 foto), quando o host toca em "Criar quarto", então o fluxo encadeado executa e a tela fecha ao finalizar com sucesso
- Dado que o fluxo completo foi bem-sucedido, quando a tela é fechada, então a lista de quartos em `my_rooms_page` é atualizada com a nova categoria/quarto
- Dado uma falha em qualquer etapa do submit, quando o erro ocorre, então um SnackBar exibe mensagem clara e o formulário permanece na tela para nova tentativa
- Dado que campos obrigatórios estão vazios (nome, valor, ao menos 1 foto), quando o host toca em "Criar quarto", então a validação inline impede a submissão

## Fora de Escopo
- Rollback automático de etapas parcialmente concluídas (ex: categoria criada mas quartos falham)
- Edição de categoria ou quarto já existente (coberto por `edit_room_page`)
- Upload de foto para cada unidade individual — fotos são associadas ao primeiro quarto criado
- Criação de novos itens no catálogo de comodidades a partir desta tela
