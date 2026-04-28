# PRD — edit-user-profile-page

> **Feature ID:** P3-C  
> **Branch:** `feat/edit-user-profile-page-integration`  
> **Prioridade:** P3 — Perfil (Feature média)  
> **Arquivo alvo:** `lib/features/profile/presentation/pages/edit_user_profile_page.dart`

---

## Contexto

A tela `edit_user_profile_page.dart` já existe na aplicação Flutter com UI completa (StatefulWidget). Ela contém seções para edição de **informações pessoais** (nome, email, telefone, data de nascimento) e **segurança** (senha atual, nova senha, confirmar nova senha), além dos botões Salvar e Cancelar com loading state.

O problema atual é que toda a lógica de dados é fictícia: o `initState` popula os campos com strings hardcoded, o submit usa `Future.delayed(1 second)` como mock, e a validação de senha compara contra a string literal `'123456'`. Não há comunicação real com o backend.

Esta feature depende de **P3-A** (`user_profile_page` com `UserProfileNotifier` em funcionamento) para que os dados do usuário autenticado estejam disponíveis em memória ao carregar a tela.

---

## Problema

A tela de edição de perfil não persiste nenhuma alteração real. O usuário preenche os campos e clica em "Salvar", mas nenhuma chamada de API ocorre — os dados voltam ao estado inicial ao recarregar a tela. A validação de senha retorna falsos positivos/negativos por comparar com um valor fixo. Isso impede que a feature de perfil seja funcional para o usuário final.

---

## Público-alvo

**Usuários finais (guests)** autenticados na plataforma ReservAqui que desejam manter seus dados pessoais atualizados ou trocar de senha.

---

## Requisitos Funcionais

1. Ao abrir a tela, os campos de informações pessoais devem ser pré-populados com os dados reais do usuário, provenientes do `UserProfileNotifier` (P3-A).
2. O usuário deve conseguir editar nome, email, telefone e data de nascimento e salvar as alterações via `PATCH /usuarios/me`.
3. Ao salvar com sucesso, o `UserProfileNotifier` deve ser atualizado com os novos dados retornados pelo backend.
4. Ao salvar com sucesso, um snackbar de confirmação deve ser exibido e a navegação deve retornar para `user_profile_page`.
5. O sistema deve tratar e exibir erros de negócio retornados pelo backend: e-mail duplicado (HTTP 409) e dados inválidos (HTTP 400).
6. Caso os campos de senha estejam preenchidos, o sistema deve chamar `POST /usuarios/change-password` com `senha_atual` e `nova_senha`.
7. A validação local deve garantir que `nova_senha` e `confirmar_nova_senha` sejam idênticas antes de enviar a requisição.
8. A validação hardcoded contra `'123456'` deve ser removida por completo.
9. O sistema deve tratar o erro de senha atual incorreta (HTTP 401 / 400) e exibir mensagem de erro específica na seção de segurança.
10. O feedback de sucesso da troca de senha deve ser separado e independente do feedback de atualização dos dados pessoais.
11. Verificar se existe campo de foto de perfil na tela; se existir e o backend não possuir endpoint de upload de avatar, levantar task EXT antes de implementar.

---

## Requisitos Não-Funcionais

- [x] **Performance:** As chamadas de API devem utilizar o padrão existente com Dio (`API_functions.dart`); o loading state visual já implementado nos botões deve encapsular o estado das requisições.
- [x] **Segurança:** Todos os endpoints requerem autenticação. O token JWT do usuário logado deve ser enviado via interceptor do Dio. Nenhuma senha deve ser logada ou armazenada em plain text.
- [x] **Acessibilidade:** Campos de formulário devem manter os labels e semântica já existentes; mensagens de erro devem ser associadas aos campos correspondentes.
- [x] **Responsividade:** A tela já é mobile-first (Flutter); manter responsividade atual — nenhuma mudança de layout é esperada.
- [x] **Estado Global:** A atualização dos dados deve refletir imediatamente no `UserProfileNotifier` para que outras telas que dependem desse estado sejam sincronizadas sem necessidade de refresh.

---

## Critérios de Aceitação

- Dado que o usuário está autenticado e navega para a tela de edição, quando a tela carregar, então os campos nome, email, telefone e data de nascimento devem exibir os valores reais do usuário (do `UserProfileNotifier`), **não** strings hardcoded.
- Dado que o usuário alterou seu nome e clicou em "Salvar", quando a requisição `PATCH /usuarios/me` for concluída com sucesso, então o `UserProfileNotifier` deve ter o estado atualizado, um snackbar verde de sucesso deve aparecer e a tela deve navegar de volta para `user_profile_page`.
- Dado que o usuário tenta salvar um e-mail já cadastrado por outro usuário, quando o backend retornar HTTP 409, então a UI deve exibir uma mensagem de erro legível ao usuário (ex: "Este e-mail já está em uso.") sem travar a tela.
- Dado que o usuário preencheu a seção de senha e `nova_senha != confirmar_nova_senha`, quando tentar submeter, então a validação local deve bloquear o envio e exibir mensagem de erro nos campos correspondentes.
- Dado que o usuário preencheu corretamente os três campos de senha e clicou em "Salvar", quando a requisição `POST /usuarios/change-password` for concluída com sucesso, então um snackbar específico de confirmação de troca de senha deve ser exibido e os campos de senha devem ser limpos.
- Dado que o usuário informou a senha atual incorretamente, quando o backend retornar HTTP 401 ou 400, então a UI deve exibir uma mensagem de erro específica na seção de segurança (ex: "Senha atual incorreta.") sem afetar a seção de dados pessoais.
- Dado qualquer cenário de submissão, quando a requisição estiver em andamento, então os botões Salvar e Cancelar devem exibir o loading state e estar desabilitados para evitar submissões duplas.

---

## Fora de Escopo

- Criação ou redesign de qualquer elemento visual da tela (a UI já está completa).
- Upload de foto/avatar de perfil (depende de verificação de endpoint no backend — se não existir, uma task EXT separada será criada).
- Notificações por e-mail ao trocar de senha.
- Histórico ou auditoria de alterações de perfil.
- Fluxo de recuperação de senha ("esqueci minha senha") — é um fluxo separado de autenticação.
- Qualquer alteração na tela de perfil de **estabelecimentos/admins** (escopo restrito ao perfil do guest).
- Testes E2E automatizados (serão tratados em task de QA separada).

---

## Dependências

| Direção | Task | Descrição |
|---------|------|-----------|
| **Requer** | P3-A | `UserProfileNotifier` populado com dados reais do usuário autenticado |

---

## Endpoints Consumidos

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| `PATCH` | `/usuarios/me` | ✅ JWT | Atualizar dados pessoais do guest |
| `POST` | `/usuarios/change-password` | ✅ JWT | Trocar senha do guest |

---

## Referências

- Task original: [`P3-C-edit-user-profile-page.md`](../../P3-C-edit-user-profile-page.md)
- Arquivo alvo: `Frontend/lib/features/profile/presentation/pages/edit_user_profile_page.dart`
- Skill de bridge de API: `.agent/skills/flutter-api-bridge/SKILL.md`
- Coleção Postman: `ReservAqui.postman_collection.json`
