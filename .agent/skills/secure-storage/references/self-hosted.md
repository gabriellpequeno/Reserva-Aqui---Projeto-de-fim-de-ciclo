# Self-Hosted Storage — MinIO & Local Disk Reference

## When to Use This

Self-hosted storage is appropriate for:
- Development environments (local disk)
- Air-gapped systems or strict data residency requirements
- Cost-constrained small-scale production (MinIO on a VPS)
- Prototyping before committing to a cloud provider

**Strongly recommended**: migrate to a managed provider (S3/GCS/Firebase) before significant scale.
Managed services handle replication, durability, and security patching automatically.

---

## MinIO

MinIO is an S3-compatible object store you run yourself. Because it speaks the S3 API, you can
use the AWS SDK with it — which makes migrating to real S3 later trivially easy.

### Setup with Docker Compose

```yaml
version: '3.8'
services:
  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
    volumes:
      - minio_data:/data
    ports:
      - "9000:9000"   # API (do NOT expose to internet directly)
      - "9001:9001"   # Console
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s

volumes:
  minio_data:
```

> The MinIO API port (9000) should NEVER be exposed directly to the internet.
> Always put a reverse proxy in front.

### nginx Reverse Proxy (TLS termination)

```nginx
server {
    listen 443 ssl;
    server_name storage.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    # Restrict API access to your backend only (not public)
    location / {
        allow 10.0.0.0/8;     # internal network only
        deny all;
        proxy_pass http://minio:9000;
        proxy_set_header Host $host;
    }
}
```

### Node.js with MinIO (S3-compatible)

Use the AWS SDK with `endpoint` pointing to your MinIO instance:

```typescript
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const s3 = new S3Client({
  region: 'us-east-1',                          // any string works for MinIO
  endpoint: process.env.MINIO_ENDPOINT,         // e.g. 'https://storage.yourdomain.com'
  credentials: {
    accessKeyId: process.env.MINIO_ACCESS_KEY,
    secretAccessKey: process.env.MINIO_SECRET_KEY,
  },
  forcePathStyle: true,                         // required for MinIO
});
```

The rest of the S3 patterns (presigned URLs, bucket policy) apply identically.

---

## Local Disk (Development / Small-Scale)

Local disk is fine for development and very small production setups, but requires careful handling
to avoid path traversal and to ensure files aren't accidentally exposed.

### ❌ Anti-pattern: serving from `public/` directly

```
/public/uploads/user-invoice.pdf  ← anyone can request this URL
```

### ✅ Correct: serve via an authorized route

Store files outside the web root, serve through a route that checks authorization:

```typescript
import path from 'path';
import fs from 'fs';
import crypto from 'crypto';

const UPLOAD_DIR = path.resolve(process.env.UPLOAD_DIR || './storage'); // outside /public

// Upload handler
export async function handleUpload(req: Request, userId: string) {
  const file = req.file; // multer
  const fileId = crypto.randomUUID();
  const ext = path.extname(file.originalname).toLowerCase();

  const ALLOWED_EXTS = ['.jpg', '.jpeg', '.png', '.webp', '.pdf'];
  if (!ALLOWED_EXTS.includes(ext)) throw new Error('File type not allowed');

  const storagePath = path.join(UPLOAD_DIR, userId, `${fileId}${ext}`);
  fs.mkdirSync(path.dirname(storagePath), { recursive: true });
  fs.renameSync(file.path, storagePath); // move from multer temp dir

  return { fileId, storagePath: `${userId}/${fileId}${ext}` }; // relative path for DB
}

// Serve handler (with auth check)
export async function serveFile(req: Request, res: Response) {
  const { fileId } = req.params;

  // 1. Look up file record in DB, verify ownership
  const record = await db.files.findUnique({ where: { id: fileId } });
  if (!record || record.ownerId !== req.user.id) {
    return res.status(403).json({ error: 'Forbidden' });
  }

  // 2. Resolve path safely — prevent traversal
  const safePath = path.resolve(UPLOAD_DIR, record.storagePath);
  if (!safePath.startsWith(UPLOAD_DIR)) {
    return res.status(400).json({ error: 'Invalid path' });
  }

  // 3. Stream file
  res.setHeader('Content-Disposition', `inline; filename="${record.originalName}"`);
  res.sendFile(safePath);
}
```

### multer configuration

```typescript
import multer from 'multer';

const upload = multer({
  dest: './tmp/uploads/',         // temp dir, move after validation
  limits: {
    fileSize: 10 * 1024 * 1024,  // 10 MB
    files: 1,
  },
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('File type not allowed'));
    }
  },
});
```

---

## Migration Path (Local/MinIO → Cloud)

When you're ready to migrate from local disk or MinIO to a cloud provider:

1. Add the cloud SDK alongside the local handler
2. Write a migration script that reads each file from local/MinIO and uploads to S3/GCS
3. Update the `storagePath` records in the DB to use cloud object keys
4. Switch the serve handler to generate signed URLs instead of streaming from disk
5. Keep the local handler running until all files are migrated and verified
6. Decommission local storage
