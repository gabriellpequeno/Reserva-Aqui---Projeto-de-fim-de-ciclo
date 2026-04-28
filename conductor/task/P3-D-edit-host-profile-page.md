# P3-D — edit_host_profile_page - feat/update-hotel-profile

## Tela
`lib/features/profile/presentation/pages/edit_host_profile_page.dart`

## Prioridade
**P3 — Perfil (Feature média)**

## Branch sugerida
`feat/edit-host-profile-page-integration`

---

## Estado Atual
Tela **existe e está implementada** (StatefulWidget com UI completa). Quase idêntica à versão do usuário.

Seções já construídas:
- **Informações pessoais:** Nome do host, Email, Telefone, Endereço (multiline)
- **Segurança:** Senha atual, Nova senha, Confirmar nova senha
- Botões **Salvar** e **Cancelar** (com loading state)

Sem integração real com API:
- `initState` com dados hardcoded
- Submit usa `Future.delayed(1 second)` como mock
- Validação de senha verifica contra `'123456'` hardcoded

---

## O que integrar

### Pré-população dos campos
- [ ] Remover dados hardcoded do `initState`
- [ ] Pré-popular campos com dados do `HostProfileNotifier` (P3-B) ao carregar a tela

### Salvar dados do hotel
- [ ] Conectar o submit ao `PATCH /hotel/me` com os campos alterados:
  - `nome`, `email`, `telefone`, `endereco`
- [ ] Tratar resposta de sucesso:
  - [ ] Atualizar estado no `HostProfileNotifier`
  - [ ] Exibir snackbar de sucesso
  - [ ] Navegar de volta para `host_profile_page`
- [ ] Tratar erros:
  - [ ] Email duplicado (409)
  - [ ] Dados inválidos (400)

### Troca de senha (seção já na tela)
- [ ] Remover validação hardcoded contra `'123456'`
- [ ] Ao submeter com campos de senha preenchidos, chamar `POST /hotel/change-password`
  - Body: `senha_atual`, `nova_senha`
- [ ] Validação local: `nova_senha === confirmar_nova_senha`
- [ ] Tratar erro de senha atual incorreta
- [ ] Feedback de sucesso separado para a troca de senha

### Upload de foto de capa do hotel
- [ ] Verificar se a tela tem campo de foto — se sim, integrar:
  - Usar `image_picker` para selecionar imagem
  - `POST /uploads/hotels/:hotel_id/cover`
  - Exibir preview antes do upload
  - Após upload, atualizar foto exibida no `HostProfileNotifier`

### Configurações do hotel
- [ ] Verificar se há campos de política (check-in/checkout, regras) na tela
- [ ] Se sim, integrar com `PATCH /hotel/configuracao`

---

## Endpoints usados

| Método | Rota                                  | Auth | Descrição                  |
|--------|---------------------------------------|------|----------------------------|
| PATCH  | `/hotel/me`                           | ✅   | Atualizar dados do hotel   |
| POST   | `/hotel/change-password`              | ✅   | Trocar senha host          |
| POST   | `/uploads/hotels/:hotel_id/cover`     | ✅   | Upload foto de capa        |
| PATCH  | `/hotel/configuracao`                 | ✅   | Atualizar config do hotel  |

---

## Dependências
- **Requer:** P3-B (`host_profile_page` com dados carregados no notifier)

## Bloqueia
— (folha)

---

## Observações
- A tela **já existe** com UI completa — foco total em substituir mocks por integração real.
- A seção de segurança já está implementada na tela, não precisa ser criada.
