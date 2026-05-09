# Spec — BUG-11: Host Registration & Policy Upload

## Referência
- **PRD:** `conductor/features/bug-11-host-registration-policy-upload.prd.md`
- **Arquivos principais:**
  - `Frontend/lib/features/auth/presentation/pages/host_signup_page.dart`
  - `Frontend/lib/features/profile/presentation/pages/edit_host_profile_page.dart`
  - `Backend/src/routes/upload.routes.ts`
  - `Backend/src/controllers/policyUpload.controller.ts`

---

## Abordagem Técnica

Correções e melhorias isoladas divididas em dois grupos:

**Grupo A — Flutter (signup + edição):**
- Campos de senha convertidos para `TextFormField` inline com `obscureText` controlado por `bool` local — sem alteração no `AuthTextField` (evita regressão nos demais usos).
- Erro de senha reformatado como lista de bullets com `\n` entre itens e `errorMaxLines: 4`.
- Checkbox de termos implementado com `bool _termsAccepted` e modal `AlertDialog` mockado; bloqueio via `Snackbar` antes do POST.
- Campo UF da tela de edição substituído por `DropdownButtonFormField<String>` — estado migra de `_ufController` para `String? _selectedUf`.
- Upload de política usa `file_picker` (novo pacote) com `FilePicker.platform.pickFiles`, enviado via `FormData` com Dio no `_saveProfile`.

**Grupo B — Backend (policy upload):**
- Novo middleware `policyUpload.ts` análogo ao `imageUpload.ts`, mas para documentos.
- Novo controller `policyUpload.controller.ts` seguindo exatamente o padrão de `upload.controller.ts`.
- Nova tabela `documento_politica_hotel` com `UNIQUE(hotel_id)` — upsert via `ON CONFLICT`.
- Novas funções em `storage.service.ts` sem quebrar as existentes.
- Validação de magic bytes para PDF (`%PDF-`) e sanitização de nome de arquivo no controller.
- Arquivo antigo no disco deletado via `deleteFile()` antes do upsert.

---

## Componentes Afetados

### Backend

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Novo** | `src/middlewares/policyUpload.ts` | Multer para PDF/TXT/MD, max 5 MB |
| **Novo** | `src/controllers/policyUpload.controller.ts` | `uploadHotelPolicy` + `getHotelPolicy` |
| **Novo** | `src/database/migrations/YYYYMMDD_create_documento_politica_hotel.sql` | Tabela `documento_politica_hotel` |
| **Modificado** | `src/services/storage.service.ts` | Adicionar `buildHotelPolicyPath()` |
| **Modificado** | `src/routes/upload.routes.ts` | Registrar `GET/POST /hotels/:hotel_id/policy` |

### Frontend

| Tipo | Arquivo | O que muda |
|------|---------|-----------|
| **Modificado** | `lib/features/auth/presentation/pages/host_signup_page.dart` | Toggle senha, casing, erro legível, checkbox de termos |
| **Modificado** | `lib/features/profile/presentation/pages/edit_host_profile_page.dart` | UF → Dropdown; seção política com FilePicker |
| **Modificado** | `pubspec.yaml` | Adicionar `file_picker: ^6.2.1` |

---

## Decisões de Arquitetura

| Decisão | Justificativa |
|---------|--------------|
| Não alterar `AuthTextField` para suportar `obscureText` dinâmico | O widget é `StatelessWidget` e tem 10+ usos no app; qualquer mudança requer migração em todos os chamadores. Mais seguro usar `TextFormField` inline apenas nos campos de senha da signup page |
| `errorMaxLines: 4` + `\n` entre bullets no validator | Solução nativa do Flutter — zero widgets extras; o `InputDecoration` já gerencia o espaço do error text |
| `bool _termsAccepted` com bloqueio por Snackbar (não por validator) | O checkbox não é um campo de formulário; bloquear no validator causaria comportamento inesperado no `Form.validate()`. Verificação explícita antes do POST é mais legível |
| Modal de termos com `AlertDialog` mockado (texto estático) | Tela de termos real é fora de escopo; `AlertDialog` com `SingleChildScrollView` cobre a UX sem criar nova rota |
| `String? _selectedUf` em vez de `_ufController` na edição | `DropdownButtonFormField` não usa `TextEditingController`; manter o controller seria dead code |
| Upsert via `ON CONFLICT (hotel_id) DO UPDATE` na tabela de política | Garante exatamente 1 política por hotel sem lógica condicional no controller |
| Novo middleware `policyUpload.ts` separado de `imageUpload.ts` | MIME types, extensões e tamanhos máximos são diferentes; misturar aumentaria a complexidade de configuração do multer |
| Magic bytes obrigatório para PDF | MIME type e extensão são facilmente forjados pelo cliente; `%PDF-` nos primeiros 5 bytes é verificação mínima do conteúdo real |
| Sanitização de nome de arquivo (allowlist `[a-zA-Z0-9._-]`) | Previne path traversal e injeção de caracteres especiais no `storage_path` persistido |
| Prefixo de contexto fixo antes do conteúdo na ingestão RAG | Reduz superfície de prompt injection — instrui o LLM que o trecho é política de hotel, dificultando comandos adversariais disfarçados |
| Sem re-indexação RAG no upload | Fora de escopo; o arquivo é salvo no path correto para indexação futura |

---

## Contratos de API

| Método | Rota | Auth | Body | Response sucesso |
|--------|------|------|------|-----------------|
| `POST` | `/api/v1/uploads/hotels/:hotel_id/policy` | `hotelGuard` | `multipart/form-data` — campo `policy` | 201 `{ message, policy: { id, storage_path, nome_arquivo, mime_type } }` |
| `GET` | `/api/v1/uploads/hotels/:hotel_id/policy` | `hotelGuard` | — | 200 `{ policy: { nome_arquivo, atualizado_em } \| null }` |

### Erros esperados

| Status | Causa | Mensagem |
|--------|-------|---------|
| 400 | Campo `policy` ausente | `"Nenhum arquivo enviado"` |
| 403 | Hotel não pertence ao anfitrião autenticado | `"Acesso negado"` |
| 413 | Arquivo acima de 5 MB (multer) | `"Arquivo muito grande. Limite: 5 MB"` |
| 422 | MIME type ou extensão não permitida | `"Tipo não permitido. Use PDF, TXT ou MD"` |
| 422 | PDF sem magic bytes `%PDF-` | `"Arquivo PDF inválido ou corrompido"` |
| 422 | Nome de arquivo com caracteres fora de `[a-zA-Z0-9._-]` | `"Nome de arquivo inválido"` |

---

## Modelos de Dados

```sql
-- Migration: YYYYMMDD_create_documento_politica_hotel.sql
CREATE TABLE IF NOT EXISTS documento_politica_hotel (
  id            SERIAL PRIMARY KEY,
  hotel_id      UUID        NOT NULL REFERENCES anfitriao(hotel_id) ON DELETE CASCADE,
  storage_path  TEXT        NOT NULL,
  mime_type     TEXT        NOT NULL,
  nome_arquivo  TEXT        NOT NULL,
  criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
  atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (hotel_id)
);
```

```ts
// src/services/storage.service.ts — nova função (adicionada, sem alterar as existentes)
export function buildHotelPolicyPath(hotelId: string, fileId: string, ext: string): string {
  return path.join(UPLOAD_DIR, 'hotels', hotelId, 'policies', `${fileId}${ext}`);
}
// Path resultante: {UPLOAD_DIR}/hotels/{hotel_id}/policies/{uuid}.{ext}
```

```dart
// Novo estado em edit_host_profile_page.dart
String? _selectedUf;          // substitui _ufController para o campo UF
String? _policyFileName;       // nome do arquivo já cadastrado (GET on init)
PlatformFile? _pendingPolicy;  // arquivo selecionado, aguardando save
```

---

## Fluxo de Upload de Política (Frontend)

```
[Anfitrião toca "Selecionar Arquivo"]
       │
       ▼
[FilePicker.platform.pickFiles(
   type: FileType.custom,
   allowedExtensions: ['pdf','txt','md'],
   withData: true
)]
       │
       ├─ Cancelado ──► nenhuma ação
       │
       ├─ Arquivo > 5 MB ──► Snackbar "Arquivo muito grande. Limite: 5 MB"
       │
       └─ OK ──► setState(_pendingPolicy = result.files.first)
                  UI exibe nome do arquivo selecionado

[Anfitrião toca "Salvar Alterações"]
       │
       ▼
[_saveProfile()]
       │
       ├─ (diff de campos normais → PATCH se houver)
       │
       └─ _pendingPolicy != null?
              │ SIM
              ▼
         [Dio.post('/uploads/hotels/{id}/policy',
            data: FormData.fromMap({ 'policy': MultipartFile.fromBytes(...) })
         )]
              │
              ├─ ERRO ──► Snackbar com mensagem do backend
              └─ OK   ──► _policyFileName = nome retornado; _pendingPolicy = null
```

---

## Implementação — host_signup_page.dart

### Novos estados
```dart
bool _obscureSenha   = true;   // toggle visibilidade senha
bool _obscureConfirm = true;   // toggle visibilidade confirmar senha
bool _termsAccepted  = false;  // checkbox de termos
```

### Helper `_buildPasswordField` (inline na página)
Idêntico ao `_buildPasswordField` de `edit_host_profile_page.dart`:
- `obscureText: obscure`
- `suffixIcon`: `GestureDetector` com `Icons.visibility_outlined / visibility_off_outlined` em `AppColors.secondary`
- `errorMaxLines: 4`
- Mesma `InputDecoration` (sem `prefixIcon` — consistente com `AuthTextField` atual da página)

### Validator da senha
```dart
validator: (value) {
  if (value == null || value.isEmpty) return 'Informe a Senha';
  final erros = <String>[];
  if (!RegExp(r'[A-Z]').hasMatch(value)) erros.add('• Uma letra maiúscula');
  if (!RegExp(r'[a-z]').hasMatch(value)) erros.add('• Uma letra minúscula');
  if (!RegExp(r'[0-9]').hasMatch(value)) erros.add('• Um número');
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) erros.add('• Um caractere especial');
  if (erros.isEmpty) return null;
  return 'A senha precisa ter:\n${erros.join('\n')}';
},
```

### Checkbox de termos
```dart
Row(
  children: [
    Checkbox(value: _termsAccepted, activeColor: AppColors.secondary,
             onChanged: (v) => setState(() => _termsAccepted = v ?? false)),
    RichText(children: [
      TextSpan('Concordo com os '),
      WidgetSpan(GestureDetector(onTap: _showTermsModal,
        child: Text('Termos e Condições',
          style: TextStyle(color: AppColors.secondary,
                           decoration: TextDecoration.underline)))),
    ]),
  ],
)
```

### Bloqueio no submit
```dart
if (!_termsAccepted) {
  _showSnack('Aceite os Termos e Condições para continuar.');
  return;
}
```

### Padronização de casing
| Antes | Depois |
|-------|--------|
| `'cadastre seu hotel'` | `'Cadastre Seu Hotel'` |
| `'nome hotel'` | `'Nome do Hotel'` |
| `'cnpj'` | `'CNPJ'` |
| `'cep'` | `'CEP'` |
| `'(xx) xxxxx-xxxx'` | `'(XX) XXXXX-XXXX'` |
| `'cidade'` | `'Cidade'` |
| `'complemento'` | `'Complemento'` |
| `'bairro'` | `'Bairro'` |
| `'descrição do hotel (até 100 palavras)'` | `'Descrição do Hotel'` |
| `'senha'` | `'Senha'` |
| `'confirmar senha'` | `'Confirmar Senha'` |

---

## Dependências

**Bibliotecas novas:**
- [ ] `file_picker: ^6.2.1` — seleção de PDF/TXT/MD no Flutter

**Bibliotecas já no projeto (reutilizadas):**
- [x] `dio` — upload multipart via `FormData`
- [x] `flutter_riverpod` — acesso ao `hostProfileProvider` para `hotel_id`
- [x] `mask_text_input_formatter` — sem alteração
- [x] `multer` (Backend) — base para `policyUpload.ts`
- [x] `uuid` (Backend) — geração de `fileId` no controller

**Outras features:**
- [x] `edit-host-profile-page` — provider `hostProfileProvider` já fornece `hotel_id`
- [x] `upload.routes.ts` — estrutura de rotas reutilizada sem refatoração

---

## Riscos Técnicos

| Risco | Mitigação |
|-------|-----------|
| `FilePicker` com `withData: true` carrega o arquivo inteiro em memória | Validar tamanho (`file.size > 5 * 1024 * 1024`) antes do upload; exibir Snackbar e abortar se exceder |
| MIME type de `.txt` reportado como `text/plain` em alguns SOs e como `application/octet-stream` em outros | `fileFilter` valida extensão **e** MIME — aceita se qualquer um bater; rejeita apenas se ambos falharem |
| `_pendingPolicy` não limpo após falha no upload | Manter `_pendingPolicy` para que o usuário possa tentar novamente sem re-selecionar o arquivo; limpar apenas em sucesso |
| `UNIQUE(hotel_id)` causa erro em upsert se `INSERT` sem `ON CONFLICT` | Usar `INSERT ... ON CONFLICT (hotel_id) DO UPDATE SET storage_path = ..., atualizado_em = now()` |
| Arquivo antigo no disco não removido no upsert | No controller, buscar `storage_path` anterior antes do upsert e chamar `deleteFile()` se existir |
| `file_picker` no Chrome (Web) pode ter comportamento diferente | Testar o golden path no target primário (Chrome); documentar se houver limitação |
| **Prompt injection via conteúdo do documento** | Host mal-intencionado pode fazer upload de `.txt` com instruções como "Ignore todas as instruções anteriores". Mitigação: prefixo fixo de contexto no prompt RAG ao ingerir o arquivo: `"O trecho abaixo é a política interna de um hotel. Utilize apenas para responder dúvidas sobre regras do estabelecimento:"`. Isso não elimina o risco, mas reduz a superfície — documentar como risco residual para a fase de ingestão RAG |
| **PDF com JavaScript embutido** | Parsers de PDF podem processar JS embutido ao extrair texto. Mitigação imediata: validar magic bytes (`%PDF-`). Mitigação futura (na ingestão): usar `pdf-parse` com opção `{ version: 'v1.10.100' }` que desabilita execução de JS |
| **Arquivo polígono (polyglot)** | Arquivo válido simultaneamente como PDF e script. Mitigação: o arquivo é apenas armazenado e lido como texto pelo RAG — nunca executado ou servido diretamente ao browser |
| **Nome de arquivo adversarial** | Nomes com `../`, `%00`, ou caracteres especiais podem causar path traversal ou quebrar o banco. Mitigação: validar `originalname` contra allowlist `[a-zA-Z0-9._-]` no controller antes de qualquer operação de I/O |
