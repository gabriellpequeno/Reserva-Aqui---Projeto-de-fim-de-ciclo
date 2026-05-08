# BUG-11 — cadastro_host + editar_perfil_host - Padronização de Fields, Campo UF e Upload de Política

## Telas
`lib/features/profile/presentation/pages/edit_host_profile_page.dart` — bug UF + upload política
`lib/features/auth/presentation/pages/register_host_page.dart` (ou equivalente) — padronização visual apenas

## Prioridade
**Média** — padronização visual + funcionalidade de política do hotel para o bot

## Branch sugerida
`fix/host-registration-policy-upload`

---

## Bugs e Melhorias

### 1. Padronizar Tela de Cadastro com Tela de Edição

- [ ] A tela de cadastro do host deve ter a **mesma estética** da `edit_host_profile_page.dart`
  - Mesma `InputDecoration` (border, borderRadius, labelStyle, hintStyle)
  - Mesmo espaçamento entre campos
  - Mesma paleta de cores e tipografia
  - Se existir `AppTextField` (criado em BUG-10), usar aqui também
- [ ] Revisar visualmente as duas telas lado a lado e alinhar qualquer diferença

### 2. Campo UF exibindo apenas uma letra

- [ ] **Bug:** o campo de UF (estado) na tela de **editar perfil do host** (`edit_host_profile_page.dart`) exibe apenas a primeira letra da sigla em vez da sigla completa (ex: "S" em vez de "SP")
  - Verificar o widget usado para o campo UF nessa tela — provavelmente um `DropdownButton` ou `TextField` com `maxLength: 1` incorreto
  - Se for `maxLength`, corrigir para `maxLength: 2`
  - Se for `Dropdown`, verificar se o `value` está sendo truncado antes de exibir
  - Testar com todas as siglas de UF (2 caracteres)
  - **Não replicar o bug para a tela de cadastro** — ao padronizar a estética do cadastro com a edição (item 1), garantir que o campo UF do cadastro usa a implementação correta, não a bugada

### 3. Upload de Arquivo de Política do Hotel

**Objetivo:** permitir que o host faça upload de um documento de política do hotel (PDF, TXT ou outro formato de texto) que será consultado pelo bot RAG ao responder perguntas sobre o hotel.

- [ ] **Campo de upload na tela de edição de perfil do host:**
  - Botão "Adicionar política do hotel" com suporte a PDF, TXT e formatos de texto simples
  - Exibir nome do arquivo atual (se já houver um carregado)
  - Permitir substituir o arquivo existente
  - Validar tamanho máximo (sugerir 5MB) e tipos aceitos

- [ ] **Destino do upload:**
  - O arquivo deve ser salvo no mesmo diretório que o bot RAG consulta para as políticas do hotel
  - Verificar no backend onde o `RagService` busca os documentos de política por hotel:
    - Se já existir um path por `hotel_id` (ex: `uploads/hotels/:hotel_id/policies/`), fazer o upload nesse endpoint
    - Se não existir, criar o endpoint `POST /uploads/hotels/:hotel_id/policy` que salva o arquivo no diretório correto
  - **Não modificar o bot** — apenas garantir que o arquivo seja salvo onde o bot já procura (ou onde ele deverá procurar)

- [ ] **Documentar o caminho esperado** — adicionar um comentário no endpoint criado indicando que os arquivos salvos aqui são consumidos pelo `RagService` para contexto de política do hotel:
  ```
  // Os arquivos salvos aqui são indexados pelo RagService para responder
  // perguntas sobre política do hotel no chatbot.
  // Caminho: uploads/hotels/:hotel_id/policies/
  ```

---

## Endpoints usados

| Método | Rota | Auth | Descrição |
|--------|------|------|-----------|
| POST | `/uploads/hotels/:hotel_id/policy` | ✅ | Upload do arquivo de política (criar se não existir) |
| GET | `/uploads/hotels/:hotel_id/policy` | ✅ | Verificar se já existe política (nome do arquivo atual) |

---

## Dependências
- BUG-10 (padronização de fields do usuário) — se `AppTextField` for criado lá, reutilizar aqui
- Não modificar o bot (P6-F) — apenas garantir que o arquivo está no lugar certo

## Observações
- Se o `RagService` usa indexação (ex: vetorização no carregamento), pode ser necessário re-indexar após o upload — verificar e documentar se for o caso, mas **não implementar** a lógica de indexação nesta task
