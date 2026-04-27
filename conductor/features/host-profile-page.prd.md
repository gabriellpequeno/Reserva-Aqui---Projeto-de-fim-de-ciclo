# PRD — Host Profile Page

## Contexto
A tela de perfil do anfitrião (`host_profile_page.dart`) existe no frontend mas exibe dados completamente hardcoded, sem nenhuma conexão ao backend.

## Problema
O anfitrião autenticado não vê seus dados reais na tela de perfil. É necessário implementar a ligação do frontend com os dados reais do backend, exibindo as informações disponíveis de acordo com o que está implementado.

## Público-alvo
Anfitrião autenticado (role `host`) que acessa a tela `/profile/host` após o login.

## Requisitos Funcionais
1. Ao entrar na tela, buscar os dados do hotel autenticado via `GET /hotel/me`
2. Exibir nome do hotel e email no `ProfileHeader`
3. Buscar fotos de capa via `GET /uploads/hotels/:hotel_id/cover` e exibir a primeira disponível
4. Exibir avaliação média do hotel se o dado estiver disponível na resposta
5. Exibir loading enquanto os dados carregam
6. Exibir mensagem de erro em caso de falha na requisição
7. Botão "Editar perfil" navega para `edit_host_profile_page`
8. Item "Meus quartos" navega para `my_rooms_page`
9. Item "Configurações" navega para `settings_page`

## Requisitos Não-Funcionais
- [ ] Responsividade: funcionar em mobile e web
- [ ] UX: exibir spinner ou skeleton durante o carregamento

## Critérios de Aceitação
- Dado que o anfitrião está autenticado, quando abre a tela de perfil, então os dados reais (nome e email) do hotel são exibidos
- Dado que os dados estão carregando, quando a tela abre, então um indicador de carregamento é exibido no lugar dos dados
- Dado que a requisição falha, quando a tela tenta carregar, então uma mensagem de erro é exibida
- Dado que o hotel possui fotos de capa cadastradas, quando a tela carrega, então a primeira foto disponível é exibida no header
- Dado que o anfitrião clica em "Editar perfil", então navega para a tela de edição
- Dado que o anfitrião clica em "Meus quartos", então navega para a tela de quartos
- Dado que o anfitrião clica em "Configurações", então navega para a tela de configurações

## Fora de Escopo
- Upload ou remoção de fotos de capa (pertence à task de upload de mídia)
- Edição de dados do perfil (pertence ao P3-D — `edit_host_profile_page`)
- Exibição de reservas ou dashboard
- Fluxo de logout
