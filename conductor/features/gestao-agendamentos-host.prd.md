# PRD — Gestão de Agendamentos do Host

## Contexto

O ReservAqui permite que hóspedes façam reservas de quartos em hotéis cadastrados. Atualmente o host não possui uma interface funcional dentro do app para gerenciar as reservas recebidas: não há como visualizar, aprovar nem cancelar pedidos. Além disso, o fluxo de quartos carece de uma proteção contra exclusão de quartos com reservas ativas, e há um bug crítico de estado de sessão que faz dados de um hotel persistirem após o logout.

## Problema

- **Gestão de reservas:** o host recebe reservas mas não consegue aprová-las nem cancelá-las pelo app, bloqueando o fluxo de confirmação do hóspede.
- **Proteção de quartos:** quartos podem ser excluídos mesmo com reservas ativas, gerando inconsistência de dados.
- **Estado de sessão:** ao trocar de conta host, o app exibe dados cadastrais do hotel anterior em vez do novo.

## Público-alvo

Hosts — proprietários e gerentes de hotéis cadastrados no ReservAqui que precisam gerenciar as reservas recebidas pelo seu estabelecimento.

---

## Requisitos Funcionais

### Tela de Agendamentos

1. O host deve ter acesso a uma tela de agendamentos a partir do menu/dashboard do host.
2. A tela deve listar todas as reservas recebidas pelo hotel, exibindo por card: código público, nome do hóspede, quarto/categoria, datas de check-in e checkout, valor total e status atual.
3. A lista deve ter filtro por status via chips horizontais roláveis: **Aguardo**, **Em Andamento**, **Hospedado**, **Finalizado**, **Cancelado**.
4. A tela deve ter, além do campo de busca textual, um **calendário** que filtra reservas por data — dias com reservas ativas devem aparecer marcados no calendário; ao selecionar um dia, a lista exibe apenas as reservas que cobrem aquela data.
5. Ao tocar em **"Detalhes"** em um card, o host é navegado para a **tela de detalhe do agendamento**.

### Tela de Detalhe do Agendamento

6. A tela de detalhe exibe todas as informações da reserva (similar à tela de detalhe do ticket do hóspede): código, hóspede, quarto, hotel, datas, total, status, forma de pagamento.
7. Para reservas em status **Aguardo**, a tela deve exibir os botões **Confirmar** e **Cancelar**.
8. Para reservas em status **Em Andamento** ou posterior, a tela deve exibir apenas o botão **Cancelar** (quando aplicável).
9. Ao tocar em **Cancelar**, exibir alerta de confirmação ("Tem certeza que deseja cancelar esta reserva?") antes de prosseguir — a ação só é executada após confirmação explícita.
10. Ao confirmar ou cancelar uma reserva, o hóspede deve receber uma **push notification** (se as notificações estiverem ativas no dispositivo do hóspede) informando a mudança de status.

### Fluxo via Notificação

11. Ao receber uma notificação de nova reserva, o host deve ser direcionado diretamente para a **tela de detalhe** daquela reserva, já com os botões Confirmar e Cancelar visíveis.

### Meus Quartos — Proteção contra Exclusão

12. Ao tentar excluir um quarto, o sistema deve verificar o número de reservas ativas (status `AGUARDANDO` ou `EM_ANDAMENTO`) para aquele quarto:
    - Se `reservas_ativas >= total_unidades_do_quarto` → bloquear exclusão e exibir diálogo: *"Este quarto possui reservas ativas. Desative-o para que não receba novas reservas."*
    - Se `reservas_ativas < total_unidades_do_quarto` → permitir exclusão normalmente.
    - Se `reservas_ativas == 0` → permitir exclusão normalmente.
13. O host deve poder **desativar** um quarto (sem excluir): quarto desativado não aparece em buscas públicas nem na listagem de reservas novas, mas as reservas existentes são mantidas.

### Estado de Sessão

14. Ao fazer logout, **todos** os providers de dados do usuário/host devem ser invalidados (`hostProfileProvider`, `userProfileProvider` e equivalentes), garantindo que ao entrar com outra conta os dados sejam buscados do zero.

---

## Requisitos Não-Funcionais

- [ ] **Performance:** a lista de agendamentos deve carregar em menos de 2s em conexão 4G; paginação ou carregamento incremental se o volume de reservas for alto.
- [ ] **Segurança:** todas as ações (aprovar, cancelar, desativar quarto) requerem autenticação como host; o endpoint deve verificar que a reserva pertence ao hotel do host autenticado.
- [ ] **Notificações:** push notifications devem funcionar com o app em background e em foreground; respeitar configuração de permissões do dispositivo.
- [ ] **Responsividade:** funcionar corretamente em iOS e Android, incluindo teclado sobrepondo o campo de busca.
- [ ] **Estado offline:** exibir mensagem adequada se não houver conexão; não permitir ações de aprovação/cancelamento sem conexão para evitar inconsistência.

---

## Critérios de Aceitação

- Dado que um hóspede cria uma reserva, quando o host abre a tela de agendamentos, então a reserva aparece na lista com status **Aguardo**.
- Dado que o host recebe uma push notification de nova reserva, quando toca na notificação, então é direcionado para a tela de detalhe daquela reserva com os botões **Confirmar** e **Cancelar** visíveis.
- Dado que o host está na tela de detalhe de uma reserva em Aguardo, quando toca em **Confirmar**, então o status muda para **Em Andamento** e o hóspede recebe push notification de aprovação.
- Dado que o host toca em **Cancelar** em qualquer reserva, quando confirma o alerta, então o status muda para **Cancelado** e o hóspede recebe push notification de cancelamento.
- Dado que o host seleciona uma data no calendário, quando a data tem reservas ativas, então a lista exibe apenas as reservas que cobrem aquela data; dias com reservas aparecem marcados no calendário.
- Dado que o host tenta excluir um quarto com `reservas_ativas >= total_unidades`, quando confirma a exclusão, então o sistema bloqueia e exibe o diálogo de orientação para desativar.
- Dado que o host desativa um quarto, quando um hóspede busca hotéis, então o quarto desativado não aparece nos resultados — mas as reservas existentes permanecem intactas.
- Dado que o host faz logout e entra com outra conta host, quando a tela de perfil carrega, então exibe apenas os dados do novo hotel, sem resquícios do hotel anterior.
- Dado que o host está offline, quando tenta aprovar ou cancelar uma reserva, então o sistema exibe mensagem de erro e não executa a ação.

---

## Fora de Escopo

- Painel de analytics ou relatórios de ocupação
- Alteração de datas de reserva pelo host
- Chat direto com o hóspede a partir do card de reserva
- Integração com calendários externos (Google Calendar, Apple Calendar, etc.)
- Aprovação em lote (múltiplas reservas de uma vez)
- Histórico de alterações de status por reserva (audit log)

---

## Referências

- Task de implementação: `conductor/__task/BUG-8-host-agendamentos-myrooms.md`
- Tela análoga (hóspede): `lib/features/tickets/presentation/pages/tickets_page.dart`
- Tela análoga detalhe (hóspede): `lib/features/tickets/presentation/pages/ticket_details_page.dart`
- Endpoints mapeados: `GET /hotel/reservas`, `PATCH /hotel/reservas/:id`, `PATCH /:hotel_id/categorias/:id`
