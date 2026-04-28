# PRD — edit-host-profile-page

## Contexto
A tela de edição de perfil do host (`lib/features/profile/presentation/pages/edit_host_profile_page.dart`) já existe com UI completa (StatefulWidget com seções de Informações pessoais, Segurança e botões Salvar/Cancelar com loading state), porém está 100% mockada: o `initState` popula os campos com dados hardcoded, o submit usa `Future.delayed(1 second)` como simulação e a validação de senha compara contra a string `'123456'`. Com a feature P3-B (`host_profile_page`) já integrada via `HostProfileNotifier`, agora temos a fonte de dados real necessária para substituir os mocks desta tela por integração com a API.

## Problema
O host não consegue editar os dados do seu hotel (nome, email, telefone, endereço) nem trocar a senha da conta. A tela de edição existe visualmente, mas não persiste nenhuma alteração no backend. Isso impede que o host mantenha as informações do hotel atualizadas após o cadastro inicial e bloqueia qualquer gestão de credenciais pela própria aplicação.

## Público-alvo
Hosts (administradores de hotéis) autenticados que precisam atualizar os dados do seu estabelecimento ou trocar a senha da conta.

## Requisitos Funcionais
1. A tela deve pré-popular os campos com os dados atuais do hotel vindos do `HostProfileNotifier` (P3-B), sem dados hardcoded no `initState`.
2. O host deve conseguir editar e salvar `nome`, `email`, `telefone` e `endereco` via `PATCH /hotel/me`.
3. Após salvar com sucesso, o sistema deve atualizar o estado no `HostProfileNotifier`, exibir snackbar de sucesso e navegar de volta para `host_profile_page`.
4. O host deve conseguir trocar a senha via `POST /hotel/change-password`, informando senha atual, nova senha e confirmação.
5. A validação de "nova senha === confirmar nova senha" deve ocorrer localmente antes do submit.
6. O sistema deve tratar erros específicos: email duplicado (409), dados inválidos (400) e senha atual incorreta, exibindo mensagens apropriadas.
7. A troca de senha deve ter feedback de sucesso separado da atualização de dados pessoais.
8. O botão "Cancelar" deve descartar as alterações e voltar para a tela anterior sem submeter.

## Requisitos Não-Funcionais
- [ ] Segurança: todas as chamadas autenticadas com JWT do host (via `getAutenticado`)
- [ ] Performance: feedback visual de loading durante submit; resposta esperada em menos de 2s
- [ ] Responsividade: funcionar em mobile e web
- [ ] Usabilidade: loading state no botão Salvar durante a requisição para evitar duplo submit
- [ ] Consistência de estado: após edição bem-sucedida, o `HostProfileNotifier` deve refletir os novos dados sem precisar de reload manual da `host_profile_page`

## Critérios de Aceitação
- Dado que o host está autenticado e acessa a tela de editar perfil, quando a tela carrega, então os campos devem vir pré-populados com os dados reais do hotel (nome, email, telefone, endereço).
- Dado que o host alterou um ou mais campos de dados pessoais, quando clicar em Salvar, então deve chamar `PATCH /hotel/me`, exibir snackbar de sucesso, atualizar o `HostProfileNotifier` e navegar de volta para `host_profile_page`.
- Dado que o host tentou salvar com um email já cadastrado em outro hotel, quando receber resposta 409, então deve exibir mensagem "Este email já está em uso".
- Dado que o host preencheu os campos de senha (atual, nova, confirmação), quando submeter, então deve validar localmente que nova senha === confirmação antes de enviar.
- Dado que a validação local de senha falhou, quando submeter, então deve exibir mensagem "As senhas não coincidem" sem chamar a API.
- Dado que o host submeteu troca de senha com senha atual incorreta, quando receber erro da API, então deve exibir mensagem "Senha atual incorreta" e manter os campos preenchidos.
- Dado que o host clicou em Cancelar, quando a ação for disparada, então deve descartar as alterações e navegar de volta sem submeter.
- Dado que uma requisição está em andamento, quando o host tentar clicar em Salvar novamente, então o botão deve estar desabilitado com indicador de loading.

## Fora de Escopo
- Upload de foto de capa do hotel (fica para entrega futura se a tela atual não tiver o campo)
- Edição de configurações do hotel (políticas de check-in/checkout, regras) via `PATCH /hotel/configuracao`
- Recuperação de senha esquecida (fluxo separado, não é troca de senha autenticada)
- Exclusão de conta do host
- Verificação em duas etapas (2FA) na troca de senha
- Histórico de alterações do perfil
