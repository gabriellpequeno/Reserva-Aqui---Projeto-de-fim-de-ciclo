# PRD — bug-11-host-registration-policy-upload

## Contexto

A tela de cadastro do host (`host_signup_page.dart`) usa `AuthTextField` sem ícones nem labels flutuantes, enquanto a tela de edição do perfil (`edit_host_profile_page.dart`) usa um helper `_buildTextField` rico com ícone colorido, label flutuante e bordas arredondadas. Além disso, o campo UF na tela de edição é um `TextField` livre quando deveria ser um `DropdownButtonFormField` com as 27 siglas válidas. Os campos de senha não possuem botão de visualização, os textos da tela estão em caixa baixa inconsistente e a mensagem de erro da senha fica truncada dentro do campo. Por fim, não existe forma de o host fazer upload de um documento de política do hotel que será consultado pelo bot RAG nas respostas ao hóspede.

## Problema

1. A inconsistência visual entre as duas telas passa uma impressão de produto inacabado.
2. O campo UF na edição aceita qualquer texto de 2 caracteres, sem garantir que seja uma sigla brasileira válida.
3. Os campos de senha no cadastro não têm botão "olhinho" para revelar o texto digitado.
4. Os textos da tela de cadastro do host estão em caixa baixa (`'cadastre seu hotel'`, `'nome hotel'`, `'cnpj'`, etc.) em vez de seguir a convenção de capitalização do produto.
5. A mensagem de erro de senha fica truncada dentro da caixa de input, tornando-a ilegível.
6. Não há checkbox de aceite de Termos e Condições no cadastro.
7. O bot RAG só conhece as configurações estruturadas do hotel (check-in/out, pets, etc.) mas não tem acesso a documentos de política textual que o host possa querer cadastrar.

## Público-alvo

Anfitriões/donos de hotel que cadastram ou editam seu estabelecimento no ReservAqui.

## Requisitos Funcionais

1. A tela `host_signup_page.dart` deve usar a mesma `InputDecoration` da tela de edição: `fillColor: colorScheme.surfaceContainer`, `borderRadius: 12`, `prefixIcon` colorido com `AppColors.secondary`, `focusedBorder` com `AppColors.secondary` de largura 2, `labelText` com `labelStyle` em `colorScheme.onSurfaceVariant`.
2. Os campos de senha (`Senha` e `Confirmar Senha`) no cadastro do host devem ter botão de toggle de visibilidade (ícone `visibility_outlined` / `visibility_off_outlined`) que alterna `obscureText` dinamicamente.
3. Todos os textos da tela de cadastro do host devem seguir a convenção de capitalização: primeira letra de cada palavra em maiúscula, siglas em caixa alta (ex: `'Cadastre Seu Hotel'`, `'Nome do Hotel'`, `'CNPJ'`, `'CEP'`, `'UF'`).
4. A mensagem de erro de validação da senha deve ser exibida de forma legível e completa, fora da caixa de input, listando cada requisito não atendido em uma linha separada com bullet point. Usar `errorMaxLines: 4` no campo.
5. A tela de cadastro do host deve ter um checkbox "Concordo com os **Termos e Condições**" antes do botão de submit. O texto "Termos e Condições" deve ser clicável e abrir um `AlertDialog` com texto mockado genérico de política de uso. O submit deve ser bloqueado (Snackbar de aviso) enquanto o checkbox não estiver marcado.
6. O campo UF em `edit_host_profile_page.dart` deve ser substituído por `DropdownButtonFormField<String>` com as mesmas 27 siglas do cadastro, pré-selecionando o valor atual do hotel.
7. A tela de edição deve ter uma seção "Política do Hotel" com:
   - Exibição do nome do arquivo atual (ou "Nenhuma política cadastrada")
   - Botão "Selecionar arquivo" que abre `FilePicker` para `.pdf`, `.txt`, `.md` com tamanho máximo de 5 MB
   - Ao salvar, faz `POST /uploads/hotels/:hotel_id/policy` com o arquivo selecionado
8. O backend deve expor `POST /uploads/hotels/:hotel_id/policy` (auth `hotelGuard`) que recebe o arquivo via multipart, salva em `storage/hotels/{hotel_id}/policies/` e registra em tabela `documento_politica_hotel` (upsert — apenas 1 por hotel).
9. O backend deve expor `GET /uploads/hotels/:hotel_id/policy` (auth `hotelGuard`) que retorna `{ policy: { nome_arquivo, atualizado_em } | null }`.

## Requisitos Não-Funcionais

- [ ] Segurança: endpoint de upload valida MIME type (`application/pdf`, `text/plain`, `text/markdown`) e tamanho máximo via multer; `hotelGuard` garante que o hotel pertence ao anfitrião autenticado.
- [ ] Consistência: decoração dos campos de senha em `host_signup_page.dart` deve ser idêntica à de `edit_host_profile_page.dart` (`_buildPasswordField`).
- [ ] UX: mensagem de erro da senha deve ser sempre legível e não truncada, independente do tamanho da tela.
- [ ] Isolamento: o RAG existente não é modificado — o arquivo de política é salvo no diretório correto para uso futuro.

## Critérios de Aceitação

- Dado que o anfitrião abre a tela de cadastro, então os campos têm ícones coloridos, labels flutuantes e bordas arredondadas idênticas à tela de edição.
- Dado que o anfitrião toca no ícone de olhinho do campo de senha, então o texto alterna entre visível e oculto.
- Dado que o anfitrião preenche a senha sem atender todos os requisitos, quando submete o formulário, então a mensagem de erro lista cada requisito faltante em linha separada, completamente visível.
- Dado que o anfitrião toca em "Termos e Condições", então um modal é aberto com o texto de política; ao fechar o modal, pode marcar o checkbox e prosseguir.
- Dado que o anfitrião toca em "Cadastrar Hotel" sem marcar o checkbox de termos, então uma Snackbar de aviso é exibida e o cadastro não é enviado.
- Dado que o anfitrião abre a tela de cadastro, então o título exibe "Cadastre Seu Hotel" e todos os hints/labels seguem a convenção de capitalização.
- Dado que o anfitrião abre a tela de edição com UF "SP" cadastrado, então o dropdown exibe "SP" pré-selecionado e aceita troca apenas para uma das 27 siglas válidas.
- Dado que o anfitrião seleciona um PDF de até 5 MB e toca "Salvar Alterações", então o arquivo é enviado ao backend, salvo em `storage/hotels/{id}/policies/` e ao reabrir a tela o nome do arquivo aparece.
- Dado que o anfitrião tenta selecionar um arquivo acima de 5 MB ou de tipo não permitido, então `FilePicker` rejeita a seleção ou o backend retorna 422 com mensagem descritiva.
- Dado que o backend recebe o arquivo, então ele sobrescreve qualquer política anterior (upsert por `hotel_id`).

## Fora de Escopo

- Validação de dígitos verificadores do CNPJ (apenas comprimento de 14 dígitos).
- Re-indexação automática do RAG após upload do documento de política (tarefa separada).
- Visualização/download do documento de política pelo host.
- Suporte a múltiplos arquivos de política por hotel.
- Modificação do bot/RAG (`dynamicIngestion.service.ts`, `rag.service.ts`).

## Contrato de API

| Método | Rota | Auth | Corpo | Resposta sucesso |
|--------|------|------|-------|-----------------|
| POST | `/api/v1/uploads/hotels/:hotel_id/policy` | hotelGuard | `multipart/form-data` campo `policy` (PDF/TXT/MD, max 5 MB) | 201 `{ message, policy: { storage_path, nome_arquivo } }` |
| GET | `/api/v1/uploads/hotels/:hotel_id/policy` | hotelGuard | — | 200 `{ policy: { nome_arquivo, atualizado_em } \| null }` |

## Arquivos a Criar / Modificar

| Ação | Arquivo | Descrição |
|------|---------|-----------|
| Modificar | `Frontend/lib/features/auth/presentation/pages/host_signup_page.dart` | Adicionar `_buildField`/`_buildPasswordField` helpers; substituir `AuthTextField` |
| Modificar | `Frontend/lib/features/profile/presentation/pages/edit_host_profile_page.dart` | Substituir TextField UF por Dropdown; adicionar seção de política com FilePicker |
| Modificar | `Frontend/pubspec.yaml` | Adicionar `file_picker: ^6.2.1` |
| Criar | `Backend/src/middlewares/policyUpload.ts` | Multer configurado para PDF/TXT/MD, max 5 MB |
| Modificar | `Backend/src/services/storage.service.ts` | Adicionar `buildHotelPolicyPath()` |
| Criar | `Backend/src/controllers/policyUpload.controller.ts` | `uploadHotelPolicy` e `getHotelPolicy` |
| Modificar | `Backend/src/routes/upload.routes.ts` | Registrar as duas novas rotas de política |
| Criar | `Backend/src/database/migrations/YYYYMMDD_create_documento_politica_hotel.sql` | Tabela `documento_politica_hotel` com UNIQUE(hotel_id) |

## Dependências

- `host_signup_page.prd.md` (implementação base do cadastro já concluída)
- `edit-host-profile-page.prd.md` (página de edição já implementada)
- Não modifica o bot (chatbot-ia.prd.md)
