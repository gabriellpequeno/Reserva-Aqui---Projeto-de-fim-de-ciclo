# PRD — host-signup-page

## Contexto

O app ReservAqui possui uma tela de cadastro de anfitrião/hotel (`lib/features/auth/presentation/pages/host_signup_page.dart`) com um formulário completo (nome do hotel, CNPJ, telefone, email, CEP, endereço, descrição, senha) mas sem nenhuma lógica: todos os campos são `AuthTextField` estáticos sem controller nem validator, e o botão de submit executa apenas `// Mock signup`. A feature de cadastro de usuário hóspede (P1-B) já foi integrada com sucesso e serve como padrão de implementação.

## Problema

O anfitrião não consegue criar uma conta no app porque:

1. O formulário não possui controllers, validators nem `FormKey`.
2. O botão "Cadastrar Hotel" não faz chamada alguma à API.
3. Não existe modelo `RegisterHostRequest` nem método no serviço de aut para o endpoint `POST /hotel/register`.
4. Após o registro, o endpoint **não retorna tokens** (`{ data: hotel }` apenas) — portanto é necessário auto-login via `POST /hotel/login` para obter `accessToken` e `refreshToken` antes de persistir a sessão e redirecionar.
5. A tela é `StatelessWidget` e precisa ser convertida para `ConsumerStatefulWidget` para gerenciar estado de loading e acessar providers.

## Público-alvo

Anfitriões/donos de hotel que desejam cadastrar seu estabelecimento no ReservAqui para disponibilizar quartos para reserva.

## Requisitos Funcionais

1. O formulário deve ter `GlobalKey<FormState>` e todos os campos devem ser convertidos para `TextEditingController` com validadores inline.
2. O sistema deve mapear os campos do formulário para o body de `POST /hotel/register` conforme contrato da entidade `Anfitriao`:
   - **Obrigatórios:** `nome_hotel`, `cnpj` (só dígitos, 14 chars), `telefone` (só dígitos), `email`, `senha`, `cep` (só dígitos, 8 chars), `uf` (2 letras), `cidade`, `bairro`, `rua`, `numero`
   - **Opcionais:** `complemento`, `descricao`
3. O campo "confirmar senha" deve ser validado localmente (deve coincidir com senha) mas **não enviado** na requisição.
4. Ao submeter com sucesso (201), o sistema deve executar auto-login via `POST /hotel/login` (email + senha) para obter os tokens, pois o endpoint de registro não retorna tokens.
5. Após obter os tokens, o sistema deve persistir a sessão com `AuthNotifier.setAuth(accessToken, refreshToken, AuthRole.host)`.
6. Após persistir a sessão, o app deve redirecionar para `/home`.
7. O botão de submit deve exibir `CircularProgressIndicator` durante o loading (substituindo o botão) e bloquear múltiplos envios.
8. O sistema deve exibir Snackbar com mensagem amigável nos seguintes erros:
   - 409 → "Este CNPJ ou e-mail já está cadastrado."
   - 400 → "Dados inválidos. Verifique os campos."
   - Genérico → "Erro no servidor. Tente novamente mais tarde."
9. A validação local (antes da chamada à API) deve verificar:
   - `nome_hotel`: não vazio
   - `cnpj`: exatamente 14 dígitos após remover não-dígitos
   - `telefone`: ao menos 10 dígitos
   - `email`: contém `@` e `.`
   - `cep`: exatamente 8 dígitos após remover não-dígitos
   - `uf`: exatamente 2 letras
   - `cidade`, `bairro`, `rua`, `numero`: não vazios
   - `senha`: ao menos 8 caracteres, contém maiúscula, minúscula, `@` e dígito (regra do backend)
   - `confirmar senha`: igual à senha

## Requisitos Não-Funcionais

- [ ] Segurança: campos `senha` e `confirmar senha` com `isPassword: true` (texto oculto); senha nunca logada.
- [ ] Responsividade: formulário com `SingleChildScrollView`, funcionar em telas pequenas.
- [ ] UX: feedback de loading visível; botão desabilitado durante submit.
- [ ] Consistência: seguir exatamente o padrão de `UserSignUpPage` (ConsumerStatefulWidget, dispose dos controllers, pattern try/catch/finally).

## Critérios de Aceitação

- Dado que o anfitrião preenche todos os campos obrigatórios com dados válidos e toca "Cadastrar Hotel", quando a API responde 201, então é feito auto-login, os tokens são salvos via `AuthNotifier` com role `host` e o app navega para `/home`.
- Dado que o anfitrião tenta cadastrar um e-mail já existente, quando a API responde 409, então exibe Snackbar "Este CNPJ ou e-mail já está cadastrado." sem sair da tela.
- Dado que o anfitrião envia dados inválidos, quando a API responde 400, então exibe Snackbar "Dados inválidos. Verifique os campos."
- Dado que o formulário está incompleto ou com campo inválido, quando o anfitrião toca "Cadastrar Hotel", então `Form.validate()` falha, erros inline aparecem nos campos e nenhuma chamada à API é realizada.
- Dado que a senha e o confirmar senha não coincidem, quando o anfitrião tenta submeter, então o campo "confirmar senha" exibe erro inline e nenhuma chamada é feita.
- Dado que o submit está em andamento, quando o anfitrião toca novamente o botão, então o toque é ignorado (botão substituído por loading).

## Fora de Escopo

- Upload de imagem de capa do hotel (`cover_storage_path` / `path` no `RegisterHotelInput`).
- Configuração operacional do hotel (`ConfiguracaoHotel`: horário de check-in/out, política de cancelamento etc.) — pertence a P3+.
- Login com Google / Apple para anfitriões.
- Validação de CNPJ com dígitos verificadores (apenas comprimento de 14 dígitos).
- Preenchimento automático de endereço via CEP (ViaCEP ou similar).
- Tela de perfil do host (`P3-B host_profile_page`).

## Contrato de API

| Método | Rota              | Auth | Corpo (obrigatório)                                                              | Resposta sucesso              |
|--------|-------------------|------|---------------------------------------------------------------------------------|-------------------------------|
| POST   | `/hotel/register` | ❌   | `nome_hotel, cnpj, telefone, email, senha, cep, uf, cidade, bairro, rua, numero` | 201 `{ data: { hotel_id, nome_hotel, email, schema_name, criado_em } }` |
| POST   | `/hotel/login`    | ❌   | `email, senha`                                                                  | 200 `{ data: hotel, tokens: { accessToken, refreshToken } }` |

## Arquivos a Criar / Modificar

| Ação      | Arquivo                                                                              | Descrição                                              |
|-----------|--------------------------------------------------------------------------------------|--------------------------------------------------------|
| Modificar | `lib/features/auth/presentation/pages/host_signup_page.dart`                        | Converter para ConsumerStatefulWidget + lógica completa |
| Criar     | `lib/features/auth/data/models/register_host_request.dart`                          | Modelo com `toJson()` para `POST /hotel/register`      |
| Modificar | `lib/features/auth/data/services/auth_service.dart`                                 | Adicionar `registerHotel()` e `loginHotel()` methods   |

## Dependências

- **Requer:** P0 (`AuthNotifier`, `DioClient`), P1-A (roteamento `/home`)
- **Bloqueia:** P2-A (`login_page`), P3-B (`host_profile_page`)
