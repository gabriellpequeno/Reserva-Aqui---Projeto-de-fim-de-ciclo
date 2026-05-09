# Plan — BUG-11: Host Registration & Policy Upload

> Derivado de: `conductor/specs/bug-11-host-registration-policy-upload.spec.md`
> Branch sugerida: `fix/host-registration-policy-upload`
> Status geral: [EM PROGRESSO — Fases 0–8 concluídas, pendente validação manual (Fase 9)]

---

## Resumo da estratégia

Ordem: **backend primeiro** (migration → storage → middleware → controller → rotas), **depois frontend signup** (toggle senha, casing, erro, termos), **depois frontend edição** (UF dropdown, upload política), **depois validação manual**.

Cada fase fecha num commit. Tasks marcadas com `⚠` exigem teste manual antes de avançar.

---

## Fase 0 — Setup & Infraestrutura [CONCLUÍDA]

- [x] Adicionar `file_picker: ^6.2.1` ao `Frontend/pubspec.yaml` e rodar `flutter pub get`
- [x] Criar `Backend/src/database/migrations/20250505_create_documento_politica_hotel.sql` com a tabela `documento_politica_hotel`
- [ ] ⚠ Aplicar a migration no banco local (`psql` ou cliente de preferência) e confirmar que a tabela foi criada

---

## Fase 1 — Backend: Storage & Middleware [CONCLUÍDA]

- [x] Adicionar `buildHotelPolicyPath(hotelId, fileId, ext)` em `Backend/src/services/storage.service.ts`
- [x] Criar `Backend/src/middlewares/policyUpload.ts` — multer com tmpdir, 5 MB, fileFilter pdf/txt/md, proteção dupla extensão
- [x] ⚠ Verificar typecheck: `npx tsc --noEmit` sem erros novos nos arquivos do feature

---

## Fase 2 — Backend: Controller & Rotas [CONCLUÍDA]

- [x] Criar `Backend/src/controllers/policyUpload.controller.ts` com `uploadHotelPolicy` e `getHotelPolicy`
- [x] Registrar rotas em `Backend/src/routes/upload.routes.ts` (GET e POST `/hotels/:hotel_id/policy`)
- [ ] ⚠ Testar com Postman/curl (validação manual — Fase 9)

---

## Fase 3 — Frontend: Signup — Toggle de Senha [CONCLUÍDA]

- [x] Estados `_obscureSenha` e `_obscureConfirm` adicionados
- [x] Helper `_buildPasswordField` com visibility toggle implementado
- [x] Substituição dos `AuthTextField(isPassword: true)` feita

---

## Fase 4 — Frontend: Signup — Erro de Senha Legível [CONCLUÍDA]

- [x] Validator com bullets por requisito não atendido + `errorMaxLines: 5`

---

## Fase 5 — Frontend: Signup — Padronização de Casing [CONCLUÍDA]

- [x] Título e todos os hints/validators atualizados conforme tabela

---

## Fase 6 — Frontend: Signup — Checkbox de Termos [CONCLUÍDA]

- [x] Estado `_termsAccepted`, modal `_showTermsModal()`, Row com Checkbox + RichText, bloqueio em `_submit()`

---

## Fase 7 — Frontend: Edit Page — UF Dropdown [CONCLUÍDA]

- [x] `_ufController` removido; `String? _selectedUf` adicionado
- [x] `_populateFromHotel`, `_onCepChanged` e `_buildDiff` atualizados
- [x] `DropdownButtonFormField` com 27 siglas implementado (`initialValue` + `key: ValueKey(_selectedUf)`)
- [ ] ⚠ Testar: abrir edição com UF existente → dropdown exibe valor → trocar → salvar → reabrir → persiste

---

## Fase 8 — Frontend: Edit Page — Seção de Política [CONCLUÍDA]

- [x] Estados `_policyFileName`, `_pendingPolicy`, `_hotelId` adicionados
- [x] `_fetchPolicy` chamado no primeiro build (após `_populateFromHotel`)
- [x] Seção `ProfileFormSection('Política do Hotel')` com texto atual, nome do arquivo pendente, botão `Selecionar Arquivo`, hint de formato/tamanho
- [x] Upload via `FormData`/`MultipartFile.fromBytes` em `_saveProfile()`; validação 5 MB no cliente
- [ ] ⚠ Testar: selecionar PDF → salvar → campo exibe nome → reabrir tela → nome ainda aparece

---

## Fase 9 — Validação [PENDENTE]

- [ ] **Toggle senha (signup):** tocar no olhinho de Senha e Confirmar Senha — texto alterna entre oculto e visível
- [ ] **Erro de senha legível:** submeter formulário com senha fraca — mensagem exibe todos os requisitos faltantes em linhas separadas, sem truncamento
- [ ] **Modal de termos:** tocar em "Termos e Condições" — modal abre com texto scrollável; "Fechar" fecha sem marcar o checkbox automaticamente
- [ ] **Bloqueio por termos:** tocar "Cadastrar Hotel" sem marcar checkbox — Snackbar de aviso; cadastro não enviado
- [ ] **Casing (signup):** conferir título `'Cadastre Seu Hotel'` e todos os hints/mensagens conforme tabela da Fase 5
- [ ] **UF dropdown (edição):** editar hotel existente — dropdown mostra sigla atual, aceita troca, salva corretamente
- [ ] **Upload política — happy path:** selecionar PDF de até 5 MB na edição → salvar → arquivo em `storage/hotels/{id}/policies/` → `documento_politica_hotel` no banco → GET retorna nome → reabrir tela → nome exibido
- [ ] **Rejeição de arquivo grande:** selecionar arquivo acima de 5 MB — Snackbar de aviso, upload não enviado
- [ ] **Segurança — PDF com magic bytes inválidos:** enviar arquivo `.pdf` cujo conteúdo não começa com `%PDF-` → backend retorna 422
- [ ] **Segurança — nome de arquivo adversarial:** enviar arquivo com nome `../../etc/passwd.txt` → backend retorna 422
- [ ] **Segurança — MIME octet-stream + extensão .txt:** enviar TXT com Content-Type `application/octet-stream` → backend aceita normalmente
- [ ] **Typecheck limpo:** `npx tsc --noEmit` (Backend) e `flutter analyze` (Frontend) sem erros novos
