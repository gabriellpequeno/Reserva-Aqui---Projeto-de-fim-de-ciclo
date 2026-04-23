# PRD — User Signup Page (P1-B)

## Contexto

O aplicativo possui uma tela de cadastro de hóspede em `lib/features/auth/presentation/pages/user_signup_page.dart`, atualmente com campos estáticos e sem integração real com a API. Esta feature é a mais externa da camada de autenticação (P1) e depende diretamente da infraestrutura de autenticação (P0 — AuthNotifier) e do roteamento (P1-A).

Branch: `feat/user-signup-page-integration`

## Problema

O formulário de cadastro não realiza chamada real à API. O botão de submit não está conectado ao endpoint `POST /usuarios/register`, não há tratamento de erros (e-mail duplicado, validação de campos), nenhum feedback visual de carregamento e nenhuma validação local antes do envio — tornando o fluxo de cadastro completamente inoperante.

## Público-alvo

Usuários finais (hóspedes) que desejam criar uma conta no aplicativo para realizar reservas.

## Requisitos Funcionais

1. Conectar o botão de submit ao endpoint `POST /usuarios/register`
2. Mapear os campos do formulário para o body da requisição: `nome` (nome completo), `email`, `senha` — verificar campos obrigatórios adicionais na entidade `Usuario`
3. Ao receber resposta de sucesso, salvar `accessToken` e `refreshToken` via `AuthNotifier` (P0)
4. Após salvar os tokens com sucesso, redirecionar o usuário para `/home`
5. Tratar erro 409 Conflict (e-mail já cadastrado) com mensagem de feedback ao usuário
6. Tratar erro 400 Bad Request (validação de campos pelo servidor) com mensagem de feedback ao usuário
7. Exibir indicador visual de loading durante a requisição (botão desabilitado ou spinner)
8. Validar localmente os campos antes de enviar: formato de e-mail válido, comprimento mínimo de senha, campos obrigatórios não vazios

## Requisitos Não-Funcionais

- [ ] Performance: resposta de UI em menos de 100ms após interação do usuário
- [ ] Segurança: senha nunca exibida em logs; comunicação via HTTPS; tokens armazenados de forma segura via AuthNotifier
- [ ] Acessibilidade: campos com labels semânticos e mensagens de erro acessíveis
- [ ] Responsividade: formulário funcional em diferentes tamanhos de tela mobile

## Critérios de Aceitação

- Dado que o usuário preencheu todos os campos válidos, quando tocar em "Cadastrar", então deve ver um indicador de loading e a requisição deve ser disparada para `POST /usuarios/register`
- Dado que a API retornou sucesso com `accessToken` e `refreshToken`, quando o cadastro for concluído, então os tokens devem ser salvos via `AuthNotifier` e o usuário redirecionado para `/home`
- Dado que o e-mail informado já possui cadastro, quando a API retornar 409 Conflict, então deve exibir mensagem de erro "E-mail já cadastrado" na tela
- Dado que a API retornar 400 Bad Request, quando houver erro de validação do servidor, então deve exibir a mensagem de erro recebida ou uma mensagem genérica de campo inválido
- Dado que o usuário deixou um campo obrigatório vazio ou inseriu e-mail no formato inválido, quando tentar submeter o formulário, então a validação local deve bloquear o envio e exibir mensagem de erro no campo correspondente
- Dado que a requisição está em andamento, quando o loading estiver ativo, então o botão de submit deve estar desabilitado para evitar múltiplos envios

## Fora de Escopo

- Login de usuários já cadastrados (coberto por P2-A — login_page)
- Recuperação ou redefinição de senha
- Cadastro via redes sociais (Google, Apple, etc.)
- Verificação de e-mail por código ou link
- Painel administrativo de usuários
- Notificações por e-mail após o cadastro

## Dependências

| Direção | Task | Motivo |
|---|---|---|
| Requer | P0 — AuthNotifier | Salvar tokens após cadastro bem-sucedido |
| Requer | P1-A — Roteamento | Redirecionar para `/home` após cadastro |
| Bloqueia | P2-A — login_page | Fluxo natural após cadastro é o login |

## Endpoints

| Método | Rota | Auth | Descrição |
|---|---|---|---|
| POST | `/usuarios/register` | ❌ | Cadastro de hóspede |
