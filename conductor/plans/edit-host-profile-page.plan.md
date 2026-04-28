# Plan — edit-host-profile-page

> Derivado de: conductor/specs/edit-host-profile-page.spec.md
> Status geral: [EM ANDAMENTO]

**Dependências:** P3-B (`host-profile-page`) — o `HostProfileNotifier` precisa estar criado e carregando os dados do hotel. P3-B já concluída na PR #21.

---

## Setup & Infraestrutura [CONCLUÍDO]

- [x] Nenhuma task de setup — sem dependências novas, sem variáveis de ambiente, sem migrations
- [x] (Paralelo, fora do escopo deste plan) Atualizar `swagger.yaml` para incluir `email` no `HotelUpdateRequest`

---

## Backend [CONCLUÍDO]

- [x] Nenhuma task — todos os endpoints (`PATCH /hotel/me`, `POST /hotel/change-password`) já existem e estão funcionais

---

## Frontend [CONCLUÍDO]

### HotelService
- [x] Adicionar método `updateMe(Map<String, dynamic> body)` → `PATCH /hotel/me` via dio autenticado
- [x] Adicionar método `changePassword(String senhaAtual, String novaSenha)` → `POST /hotel/change-password` via dio autenticado (já existia)

### HostProfileNotifier (`lib/features/profile/presentation/providers/host_profile_provider.dart`)
- [x] Adicionar método `updateProfile(Map<String, dynamic> diff)` — chama `HotelService.updateMe`; no sucesso atualiza `state.hotel` com resposta
- [x] Adicionar método `changePassword(String senhaAtual, String novaSenha)` — chama `HotelService.changePassword`

### Helper ViaCEP
- [x] Criar utilitário `fetchViaCep(String cep)` que retorna `Map` com `{uf, cidade, bairro, rua}` ou `null` em erro/timeout (3s)

### EditHostProfilePage (`lib/features/profile/presentation/pages/edit_host_profile_page.dart`)
- [x] Converter de `StatefulWidget` para `ConsumerStatefulWidget`
- [x] Remover dados hardcoded do `initState`; pré-popular controllers com dados de `hostProfileProvider`
- [x] Tratar estados de loading/erro do provider ao abrir a tela
- [x] Remover validação hardcoded de senha contra `'123456'`
- [x] Substituir campo único "Endereço" por 7 campos: `cep`, `uf`, `cidade`, `bairro`, `rua`, `numero`, `complemento`
- [x] Aplicar máscara ao campo CEP (00000-000) na UI; remover máscara antes do submit
- [x] Integrar lookup ViaCEP: on-change do CEP com debounce 500ms → preencher `uf`, `cidade`, `bairro`, `rua`
- [x] Implementar diff contra estado inicial no submit: enviar apenas campos alterados no `PATCH /hotel/me`
- [x] Se diff vazio e sem troca de senha: exibir snackbar "Nenhuma alteração a salvar" sem chamar API
- [x] Submit em sequência: primeiro `updateProfile(diff)`; só se OK, chamar `changePassword` (se campos de senha preenchidos)
- [x] Validação local: `novaSenha === confirmarNovaSenha` antes de chamar API
- [x] Tratar erro 409 no update → mensagem "Este email já está em uso" no campo email
- [x] Tratar erro 400 no update → mensagem de dados inválidos
- [x] Tratar erro 401 no change-password → mensagem "Senha atual incorreta" mantendo campos preenchidos
- [x] Feedback de sucesso separado: snackbar para update; snackbar + logout + navegação para login após change-password
- [x] Flag `isSubmitting` desabilitando o botão Salvar durante chamadas
- [x] Botão Cancelar: descartar alterações e voltar sem submeter

---

## Validação [PENDENTE]

- [ ] Verificar pré-população dos campos com dados reais do hotel ao abrir a tela
- [ ] Verificar edição de nome, email, telefone, descrição → `PATCH /hotel/me` + snackbar de sucesso + dados refletidos na `host_profile_page` sem reload manual
- [ ] Verificar edição de endereço via 7 campos → payload contém apenas campos alterados
- [ ] Verificar lookup ViaCEP: digitar CEP válido → preenche uf/cidade/bairro/rua automaticamente
- [ ] Verificar CEP inválido ou ViaCEP fora do ar → mensagem "CEP não encontrado" sem bloquear submit
- [ ] Verificar submit com email já em uso por outro hotel → mensagem 409 tratada corretamente
- [ ] Verificar troca de senha com senha atual correta → sucesso + logout automático + redirect para login
- [ ] Verificar troca de senha com senha atual incorreta → mensagem específica, campos preservados
- [ ] Verificar validação local: nova senha ≠ confirmação → mensagem "As senhas não coincidem" sem chamar API
- [ ] Verificar submit sem alterações → mensagem "Nenhuma alteração a salvar" sem chamar API
- [ ] Verificar botão Cancelar → descarta alterações e volta sem submeter
- [ ] Verificar double-click no Salvar → botão desabilita durante loading
- [ ] Verificar funcionamento em mobile e web
