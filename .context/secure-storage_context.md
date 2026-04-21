# Context: Secure Storage

> Last updated: 2026-04-15T04:17:00-03:00
> Version: 1

## Purpose

Implementação de storage local seguro para o ReservAqui:
- **Fotos de capa do hotel**: até 5 por orientação (portrait + landscape), servidas publicamente via rota Express
- **Fotos dos quartos**: até 10 por orientação por quarto, servidas publicamente via rota Express
- Todos os limites e tamanho máximo configuráveis via variáveis de ambiente

## Architecture / How It Works

- **Storage backend**: Local Disk (Node.js + fs) — sem dependências de cloud
- **Access pattern**: público-read (GET sem auth), authenticated-write (POST/DELETE requer JWT de anfitrião)
- **Upload flow**: multipart/form-data → multer (temp dir) → validação magic bytes → move para `storage/` → salva path no DB
- **Segurança no serving**: arquivos servidos APENAS via rota Express (`res.sendFile`) com verificação de path traversal. Nunca expostos diretamente como arquivos estáticos.
- **Orientação**: cada foto tem campo `orientacao: 'portrait' | 'landscape'`. O Flutter filtra via query param `?orientacao=portrait`
- **Path structure**: `storage/hotels/{hotel_id}/cover/{orientacao}/{uuid}.ext` e `storage/hotels/{hotel_id}/rooms/{quarto_id}/{orientacao}/{uuid}.ext`

## Affected Project Files

| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `src/services/storage.service.ts` | Yes | Abstração do filesystem (moveFile, deleteFile, streamFile, buildPaths) |
| `src/middlewares/imageUpload.ts` | Yes | Configuração do multer com allowlist de MIME e extensão |
| `src/controllers/upload.controller.ts` | Yes | Lógica de upload, validação magic bytes, ownership check, DB insert |
| `src/routes/upload.routes.ts` | Yes | Rotas REST para upload/serve/delete/list |
| `src/app.ts` | Yes | Registra as rotas `/api/uploads` |
| `database/scripts/002_add_storage_master.sql` | Yes | Migration: renomeia `path→cover_storage_path` + cria `foto_hotel` no master |
| `database/scripts/002_add_storage_tenant.sql` | Yes | Migration: cria `quarto_foto` em tenants existentes |
| `database/scripts/init_tenant.sql` | Yes | Inclui `quarto_foto` para novos tenants provisionados |
| `.env` / `.env.example` | Yes | Variáveis de storage configuráveis |

## Code Reference

### `storage.service.ts` — funções principais

**`buildHotelCoverPath(hotelId, orientacao, fileId, ext)`** → constrói path absoluto para foto de capa  
**`buildRoomPhotoPath(hotelId, quartoId, orientacao, fileId, ext)`** → constrói path absoluto para foto de quarto  
**`resolveSafe(storagePath)`** → valida que path não escapa de UPLOAD_DIR (anti path traversal)  
**`streamFile(storagePath, res)`** → stream seguro do arquivo para a Response  
**`deleteFile(storagePath)`** → deleta arquivo com falha silenciosa  

### `upload.controller.ts` — endpoints

| Função | Endpoint | Auth |
|--------|----------|------|
| `uploadHotelCover` | POST /api/uploads/hotels/:hotel_id/cover | Sim |
| `deleteHotelCover` | DELETE /api/uploads/hotels/:hotel_id/cover/:foto_id | Sim |
| `serveHotelCover` | GET /api/uploads/hotels/:hotel_id/cover/:foto_id | Não |
| `listHotelCovers` | GET /api/uploads/hotels/:hotel_id/cover | Não |
| `uploadRoomPhoto` | POST /api/uploads/hotels/:hotel_id/rooms/:quarto_id | Sim |
| `deleteRoomPhoto` | DELETE /api/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id | Sim |
| `serveRoomPhoto` | GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id/:foto_id | Não |
| `listRoomPhotos` | GET /api/uploads/hotels/:hotel_id/rooms/:quarto_id | Não |

## Key Design Decisions

- **Local disk em vez de Firebase Storage**: elimina custo operacional na fase atual; `storage.service.ts` tem interface abstraída para migração futura para S3/GCS com mínima alteração nos callers
- **Magic bytes validation**: MIME é re-verificado nos primeiros bytes do arquivo no servidor — não apenas o header declarado pelo cliente (previne MIME confusion attacks)
- **portrait/landscape separados**: cada orientação tem seu próprio contador de limite, não dividem o quota. Um hotel pode ter 5 portraits + 5 landscapes = 10 fotos de capa no total
- **withTenant para queries de quarto**: respeita a arquitetura multi-tenant via schema lógico — nunca acessa tabelas de tenant sem configurar o search_path primeiro
- **storage_path no DB, nunca URL**: o banco armazena o caminho relativo; a URL é construída dinamicamente pelo controller ao servir ou listar

## ENV Vars

| Variável | Default | Descrição |
|----------|---------|-----------|
| `UPLOAD_DIR` | `./storage` | Raiz do armazenamento (fora de public/) |
| `UPLOAD_MAX_SIZE_MB` | `10` | Tamanho máximo por imagem em MB |
| `UPLOAD_MAX_HOTEL_COVER` | `5` | Máx fotos de capa por hotel por orientação |
| `UPLOAD_MAX_ROOM_PHOTOS` | `10` | Máx fotos por quarto por orientação |

## Security Controls Active

- [x] Type validation (multer allowlist: jpeg, png, webp)
- [x] Extension double-attack prevention
- [x] Size limits via UPLOAD_MAX_SIZE_MB
- [x] Magic bytes server-side re-verification
- [x] Sanitized filenames (UUID — input do usuário nunca vira path)
- [x] Path traversal prevention (resolveSafe)
- [x] Access control on mutations (anfitrião ownership via JWT + DB check)
- [x] Public serving via Express route only (nunca static files diretos)
- [x] Upload limits por orientação (MAX_HOTEL_COVER / MAX_ROOM_PHOTOS)
- [x] Temp file cleanup em toda falha de validação

## Next Steps (pré-produção)

- Executar `init_master.sql` no banco master (re-executar é seguro — todos os CREATE são `IF NOT EXISTS`)
- Para tenants já existentes: executar `init_tenant.sql` manualmente com o `search_path` correto
- Garantir permissão de escrita no `UPLOAD_DIR` em produção
- Adicionar rate limiting específico no endpoint de upload (via express-rate-limit)
- Considerar migration para S3 quando volume crescer (apenas trocar `storage.service.ts`)

## Changelog

### v1 — 2026-04-15
- Implementação inicial completa: storage local com orientação portrait/landscape
- Criados: `storage.service.ts`, `imageUpload.ts`, `upload.controller.ts`, `upload.routes.ts`
- Migrations SQL: `002_add_storage_master.sql`, `002_add_storage_tenant.sql`
- `init_tenant.sql` atualizado com tabela `quarto_foto`
- Variáveis de ambiente documentadas em `.env` e `.env.example`
