# topo da tela
- texto 'Reserva' em negrito
- um botaão de retornar a esquerda
- um botão de notificação a direita
    - ao clicar abre tela de notificações


# corpo da tela

- ticket com os dados expostos
    - nome do hóspede
    - nome do quarto
    - nome do hotel
    - data de check-in - check-out
    - status
    - preço total
    - botão de alterar status
        - ao clicar abre um modal com os status
            - aprovado
            - hospedado
            - cancelado
            - concluído
                - ao clicar um alerta deve aparecer
                    - 'Tem certeza que deseja mudar para [status] esta reserva?'
                        - Botão 'Sim'
                        - Botão 'Não'
                        
**importante**
- os status corretos estao no banco de dados mas para a construção das telas vamos usar mockados 
- atualizar na integração front-back
