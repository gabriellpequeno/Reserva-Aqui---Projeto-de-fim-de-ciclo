# topo da tela
- logo usar variação 'logoDark.svg'
- texto 'Notificações' em negrito
- um botaão de retornar para a tela de perfil a esquerda

- *O botão com o sino de notificação deve sair*


# corpo da tela

- Lista de notificações vertical
    - A esquerda da notificação tem um texo referente ao tipo de notificação
            ┌─────────────────────────────┐
            │ *Nome da notificação*       │
            │ sobre da notificação        │
            └─────────────────────────────┘

    - A direita da notificação tem um icone de "x" para fechar a notificação
        - ao clicar em "x" ele deve fechar a notificação
    - Entre o nome da notificação e o sobre da notificação um texto 'Ver Detalhes'.
        - ao clicar em 'Ver Detalhes' ele deve abrir uma a tela referente a notificação.
            - exemplo: se a notificação for sobre uma atualização de status de um ticket, ele deve abrir o ticket.
            - exemplo: se a notificação for sobre uma nova mensagem, ele deve abrir o chat.

# rodapé da tela
- um botão de 'Limpar' para limpar todas as notificações
    - ao clicar em 'Limpar' ele deve limpar todas as notificações
- Deve ter a bottomNavBar