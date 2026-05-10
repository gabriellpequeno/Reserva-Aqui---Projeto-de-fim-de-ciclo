# topo da tela
- texto 'Minhas Reservas' em negrito
- barra de busca:
    - tipos de busca:
        - nome do hotel
        - quarto
        - id do ticket
        - status
    - um icone de busca a direita
- um botaão de retornar para a tela de perfil a esquerda
- um botão de notificação a direita
    - ao clicar abre tela de notificações


# corpo da tela

## filtro
- deve ter um filtro para filtrar as reservas por status
    - todos
    - confirmadas
    - canceladas
    - pendentes
    - concluídas
- filtro deve aparece lista lateralmente com os nomes mudando o estado de ativo para inativo ao ser selecionado
    - ativado cor laranja
    - inativo cor cinza
    - estetica:
┌────────────────────────────────────────────────────┐
│ *Aguardo*   aprovado   hospedado   cancelado  finalizado       │
│                                                    │
└────────────────────────────────────────────────────┘ 
## tickets
- lista de tickets
    - cada ticket deve ter um botão de ver detalhes abaixo.
        - ao clicar em ver detalhes ele deve abrir uma tela de detalhes do ticket
    - Cada ticket deve ter uma imagem a direita
    - Cada ticket deve ter a esquer:
        - nome do hotel
        - status
        - data de check-in - check-out
        - endereço

### tickets
    - os tickets tem variações de cor dependendo do status
        - aguardo: laranja
        - aprovado: azul
        - hospedado: verde
        - canceladas: vermelho
        - concluídas: cinza

**importante**
- os status corretos estao no banco de dados mas para a construção das telas vamos usar mockados 
- atualizar na integração front-back

# rodapé da tela
- deve ter a bottomNavBar