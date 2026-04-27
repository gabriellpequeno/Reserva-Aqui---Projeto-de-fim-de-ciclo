# P3-C — edit_user_profile_page - feat/update-guest-profile

## Tela
`lib/features/profile/presentation/pages/edit_user_profile_page.dart`

## Prioridade
**P3 — Perfil (Feature média)**

## Branch sugerida
`feat/edit-user-profile-page-integration`

---

## Estado Atual
Tela **existe e está implementada** (StatefulWidget com UI completa).

Seções já construídas:
- **Informações pessoais:** Nome, Email, Telefone, Data de nascimento
- **Segurança:** Senha atual, Nova senha, Confirmar nova senha
- Botões **Salvar** e **Cancelar** (com loading state)

Sem integração real com API:
- `initState` popula campos com dados hardcoded (`"Acesse agora"`, `"usuario@user.com"`)
- Submit usa `Future.delayed(1 second)` como mock
- Validação de senha verifica contra `'123456'` hardcoded

---

## O que integrar

### Pré-população dos campos
- [ ] Remover dados hardcoded do `initState`
- [ ] Pré-popular campos com dados do `UserProfileNotifier` (P3-A) ao carregar a tela

### Salvar dados pessoais
- [ ] Conectar o submit ao `PATCH /usuarios/me` com os campos alterados:
  - `nome`, `email`, `telefone`, `data_nascimento`
- [ ] Tratar resposta de sucesso:
  - [ ] Atualizar estado no `UserProfileNotifier`
  - [ ] Exibir snackbar de sucesso
  - [ ] Navegar de volta para `user_profile_page`
- [ ] Tratar erros:
  - [ ] Email duplicado (409)
  - [ ] Dados inválidos (400)

### Troca de senha (seção já na tela)
- [ ] Remover validação hardcoded contra `'123456'`
- [ ] Ao submeter com campos de senha preenchidos, chamar `POST /usuarios/change-password`
  - Body: `senha_atual`, `nova_senha`
- [ ] Validação local: `nova_senha === confirmar_nova_senha`
- [ ] Tratar erro de senha atual incorreta (401/400)
- [ ] Feedback de sucesso separado para a troca de senha

### Upload de foto de perfil
- [ ] ⚠️ Verificar se existe campo de foto na tela — se sim, verificar se o backend tem endpoint de upload para avatar de usuário
- [ ] Se não existir endpoint no back → levantar task EXT

---

## Endpoints usados

| Método | Rota                         | Auth | Descrição              |
|--------|------------------------------|------|------------------------|
| PATCH  | `/usuarios/me`               | ✅   | Atualizar dados guest  |
| POST   | `/usuarios/change-password`  | ✅   | Trocar senha guest     |

---

## Dependências
- **Requer:** P3-A (`user_profile_page` com dados carregados no notifier)

## Bloqueia
— (folha)

---

## Observações
- A tela **já existe** com UI completa — foco total em substituir mocks por integração real.
- A seção de segurança já está implementada na tela, não precisa ser criada.
