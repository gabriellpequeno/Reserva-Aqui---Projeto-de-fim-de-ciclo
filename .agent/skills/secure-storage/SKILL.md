---
name: secure-storage
description: >
  Secure storage implementation skill. Guides the design and implementation of any file/object storage system
  with a security-first methodology: discovers architecture needs through structured questions, proposes the most
  secure and optimized approach before writing a single line of code, and then implements it.
  Activate this skill whenever the user mentions: file upload, object storage, image/video/document storage,
  S3, GCS, Firebase Storage, Supabase Storage, local disk storage, CDN, media uploads, presigned URLs,
  multipart upload, storage buckets, secure file access, or anything involving storing user-generated files.
  Also trigger when the user asks to "add storage", "handle uploads", "store files securely", or "set up a CDN".
---

# Secure Storage Skill

This skill exists because storage is one of the most commonly misimplemented features in modern apps — it's easy
to *make files accessible*, but it takes deliberate thought to make them *secure, cost-efficient, and scalable*.
The skill forces a quick architectural conversation before any implementation so you don't end up needing to
re-architect later.

---

## Context Load (MANDATORY — run this first)

Before doing any analysis, research, or implementation, check for a saved context file:

1. Look for `.context/secure-storage_context.md` at the project root.
2. If the file **exists**: read it in full. Use the Architecture, Affected Project Files, Code Reference, and Key Design Decisions sections to restore your working context. Skip any research or codebase exploration that would duplicate what is already documented there. Inform the user:
   > "Context restored from `.context/secure-storage_context.md` (v<N>, last updated <date>). Continuing from previous session."
3. If the file **does not exist**: proceed normally — explore the codebase, gather context, and document it at the end via the Context Storage step.

> **Rule:** Never ignore an existing context file. It exists precisely to avoid re-analysis. Trust it, and update it if the implementation changes.

---

## Phase 1 — Architecture Discovery (always run before implementation)

Never jump straight into implementation. Storage systems touch security, cost, scalability, and compliance
simultaneously. A 5-minute conversation up front saves days of refactoring.

Ask the user these questions (you can ask them together, not one by one):

### 1.1 — What are you storing?

Understanding the data type drives the entire architecture:

| Data Type | Key Concern |
|-----------|-------------|
| User profile images / avatars | Size limits, format validation, CDN caching |
| Documents (PDF, DOCX) | Virus scanning, access control, versioning |
| Videos / audio | Multipart upload, transcoding, bandwidth cost |
| App assets / static files | Immutability, cache-busting, CDN |
| Private user data (medical, financial) | Encryption at rest, audit logs, compliance |

### 1.2 — Who accesses the files, and how?

Access control is the most common storage security failure:

- **Public read, authenticated write** (e.g., product images) → CDN + signed upload URLs
- **Fully private** (e.g., invoices, medical records) → Presigned/expiring download URLs, never public URLs
- **Tenant-isolated** (multi-tenant SaaS) → Bucket-per-tenant or path-based isolation with server-enforced checks
- **Admin-only** (e.g., internal reports) → Backend proxy pattern, files never exposed directly

### 1.3 — What's the infrastructure context?

Adapt the storage backend to what the project already uses:

- **Firebase project** → Firebase Storage (GCS under the hood) with Security Rules
- **AWS environment** → S3 + CloudFront
- **GCP environment** → GCS + Cloud CDN
- **Supabase** → Supabase Storage
- **Self-hosted / VPS** → MinIO or local disk with a serving layer (nginx/caddy)
- **Node.js / NestJS backend** → Suggest `multer` + cloud SDK or presigned URLs
- **No preference** → Recommend based on the existing stack

### 1.4 — Volume and performance expectations?

- Expected max file size per upload?
- Expected monthly upload volume (GB)?
- Do files need to be served from a CDN (global users)?
- Is real-time access required, or is async processing acceptable?

### 1.5 — Compliance and retention?

- Do files contain PII, health data, or financial data?
- Are there regulatory requirements (LGPD, GDPR, HIPAA)?
- How long should files be retained? Is deletion automation needed?

---

## Phase 2 — Proposal (present before writing code)

After gathering answers, produce a written proposal structured as follows. Show it to the user and wait
for approval before starting implementation.

```
## Storage Architecture Proposal

### Recommended Backend
[Name the provider and why — match to existing stack, avoid introducing unnecessary new services]

### Access Pattern
[Describe: public vs private, how URLs are generated, how access is revoked]

### Upload Flow
[Client → Backend → Storage OR Client → Presigned URL → Storage — explain the tradeoff]

### Security Controls
- [ ] File type validation (allowlist, not denylist)
- [ ] File size limits enforced server-side
- [ ] Filename sanitization (no path traversal)
- [ ] Virus/malware scanning (if applicable)
- [ ] Encryption at rest (provider default or customer-managed keys)
- [ ] Encryption in transit (TLS — should be guaranteed by the provider)
- [ ] Access control enforcement (who can read/write/delete)
- [ ] Signed/expiring URLs for private files
- [ ] Audit logging (who accessed what, when)

### Cost Estimate
[Rough GB/month storage + egress estimate if volume was provided]

### Risks and Trade-offs
[What you're deliberately NOT doing and why]
```

Only proceed after the user confirms or adjusts the proposal.

---

## Phase 3 — Implementation

Implement based on the confirmed proposal. Follow these patterns by provider:

### Firebase Storage

- Use **Security Rules** to enforce access — never rely solely on backend logic for GCS-level access.
- Generate **upload-only tokens** on the backend; never expose service account credentials to the client.
- Store the `gs://` path in the database, not the public URL — generate signed URLs on demand.
- Example Security Rule pattern (tenant isolation):
  ```
  match /users/{userId}/{allPaths=**} {
    allow read, write: if request.auth.uid == userId;
  }
  ```
- For public assets (e.g., product images), use `allow read: if true;` only on explicitly public paths.

### AWS S3

- Use **presigned PUT URLs** for client-side uploads — never route file bytes through your backend.
- Set `Content-Type` and `Content-Length` constraints in the presigned URL to prevent type confusion attacks.
- Enable **S3 Block Public Access** at the account level; expose files only via CloudFront signed URLs.
- Use **S3 Object Tagging** for lifecycle policies (auto-delete temp files after N days).
- IAM role for the backend should have the minimum permissions needed (principle of least privilege).

### Google Cloud Storage (GCS)

- Same presigned URL pattern as S3 (`signedUrl` via the Node.js SDK).
- Use **Uniform Bucket-Level Access** — avoid legacy ACLs.
- Enable **Object Versioning** for critical data that must not be accidentally deleted.

### Supabase Storage

- Enforce Row-Level Security (RLS) on the `storage.objects` table.
- Use private buckets and generate signed URLs via `supabase.storage.from(bucket).createSignedUrl()`.
- Never use the service role key on the client side.

### MinIO / Self-hosted

- Always put a reverse proxy (nginx, Caddy) in front — never expose MinIO directly.
- Enable TLS on the MinIO endpoint.
- Use presigned URLs for all client-facing access, same as S3.
- Set up lifecycle rules for temp file cleanup.

### Local Disk (dev/small scale only)

- Store files outside the web root — never serve from `public/` directly.
- Serve via a dedicated route that checks authorization before streaming the file.
- Use `path.basename()` / `path.resolve()` to prevent path traversal.
- Strongly recommend migrating to a cloud provider before production.

---

## Security Checklist (enforce on every implementation)

Run through this before considering the feature complete:

- [ ] **Type validation**: allowlist of MIME types checked server-side, not just client-side
- [ ] **Extension validation**: double-extension attacks (e.g., `malware.php.jpg`)
- [ ] **Size limit**: enforced in the upload handler, not just documented
- [ ] **Sanitized filenames**: UUIDs or slugified names — user input never becomes a filesystem path
- [ ] **No direct public URLs for private files**: generate expiring signed URLs per request
- [ ] **Authorization check before file access**: verify the requesting user owns or has permission to the file
- [ ] **Storage credentials not exposed to client**: presigned URLs, not SDK keys
- [ ] **Temp file cleanup**: uploaded files that fail processing are deleted
- [ ] **Rate limiting on upload endpoints**: prevent storage abuse
- [ ] **Audit log**: at minimum, log who uploaded/downloaded which file and when

---

## Common Anti-patterns to Avoid

These are mistakes that look fine until they aren't:

| Anti-pattern | Why it's dangerous | Fix |
|---|---|---|
| Storing raw user filename as the storage path | Path traversal, enumeration | Use UUID as key, store original name in DB |
| Public bucket with "private" paths | Security by obscurity — URLs leak | Use private bucket + presigned URLs |
| Passing file bytes through backend for uploads | Wastes CPU/memory, limits file size | Presigned PUT URL directly to storage |
| Trusting client-provided Content-Type | MIME type confusion attacks | Re-detect MIME on the backend (magic bytes) |
| No size limit | Storage cost abuse, DoS | Enforce in middleware AND presigned URL constraints |
| Permanent public URLs for user data | Can't revoke access after the fact | Expiring signed URLs (15min–1hr typical) |
| Service account key in client code | Complete account takeover | Backend-only credentials, presigned URLs for client |

---

## Reference Files

For deep dives into specific providers, read:

- `references/firebase-storage.md` — Firebase Storage patterns and Security Rules examples
- `references/s3-patterns.md` — S3 presigned URL patterns, IAM, CloudFront signing
- `references/self-hosted.md` — MinIO / local disk patterns for dev and small-scale production

> Read only the reference file for the provider chosen in Phase 2.

---

## Context Storage (MANDATORY — run this last)

After completing the implementation, create or update `.context/secure-storage_context.md`
at the **project root** (not inside the skill folder). If the file already exists, update
it to reflect the current state — never delete the Changelog section.

### File to write: `.context/secure-storage_context.md`

Use this template (fill in all sections):

```markdown
# Context: Secure Storage

> Last updated: <ISO 8601 datetime>
> Version: <N>

## Purpose
Description of what storage system was implemented and why.

## Architecture / How It Works
- Storage backend chosen (Firebase / S3 / GCS / Supabase / MinIO / local)
- Access pattern (public / private / tenant-isolated)
- Upload flow (backend-proxied / presigned URL)
- Key dependencies or external services

## Affected Project Files
List ONLY the project files that use or depend on this system.

| File | Uses this system? | Relationship |
|------|:-----------------:|--------------|
| `path/to/file.ts` | Yes | Handles upload endpoint |

## Code Reference
Key functions/classes implemented, with inline explanations:

### `path/to/file.ts` — `generateUploadUrl(args)`

```typescript
// paste relevant snippet here
```

**How it works:** plain-language explanation.
**Coupling / side-effects:** what else depends on this or is affected by changes here.

## Key Design Decisions
- Decision made and why (trade-offs, alternatives considered)

## Security Controls Active
- [ ] Type validation
- [ ] Size limits
- [ ] Signed URLs
- [ ] Access control
- [ ] Audit logging

## Changelog

### v<N> — <date>
- What was implemented or changed in this session
```

After writing the file, tell the user:
> "Context saved to `.context/secure-storage_context.md` — future sessions can load this file to restore full context instantly, without re-reading the codebase."
