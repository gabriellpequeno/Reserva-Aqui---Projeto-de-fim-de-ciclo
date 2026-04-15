# AWS S3 — Deep Dive Reference

## Overview

S3 is the reference implementation for object storage. The key architectural principle:
**files never travel through your backend** — clients upload/download directly from S3 using
**presigned URLs** that your backend generates.

---

## Upload Flow (Presigned PUT URL)

```
Client                     Your Backend            S3
  │                              │                  │
  │── POST /uploads/prepare ────>│                  │
  │                              │── signedPutUrl ─>│
  │<── { uploadUrl, key } ───────│                  │
  │                              │                  │
  │──────────── PUT (file bytes) ─────────────────>│
  │<──────────── 200 OK ───────────────────────────│
  │                              │                  │
  │── POST /uploads/confirm ────>│                  │
  │   { key, originalName }      │── validate ────>│
  │<── { fileId, readUrl } ──────│                  │
```

### Generate a presigned PUT URL (Node.js)

```typescript
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const s3 = new S3Client({ region: process.env.AWS_REGION });

export async function generateUploadUrl(
  userId: string,
  contentType: string,
  maxBytes: number
): Promise<{ uploadUrl: string; key: string }> {
  const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

  if (!ALLOWED_TYPES.includes(contentType)) {
    throw new Error('File type not allowed');
  }

  const key = `users/${userId}/${crypto.randomUUID()}`; // UUID key, never user input

  const command = new PutObjectCommand({
    Bucket: process.env.S3_BUCKET,
    Key: key,
    ContentType: contentType,
    ContentLength: maxBytes,   // enforced by S3 — client cannot exceed this
    Metadata: {
      uploadedBy: userId,
      uploadedAt: new Date().toISOString(),
    },
  });

  const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 900 }); // 15 min
  return { uploadUrl, key };
}
```

### Generate a presigned GET URL

```typescript
import { GetObjectCommand } from '@aws-sdk/client-s3';

export async function generateReadUrl(key: string, expiresInSeconds = 3600): Promise<string> {
  const command = new GetObjectCommand({
    Bucket: process.env.S3_BUCKET,
    Key: key,
  });
  return getSignedUrl(s3, command, { expiresIn: expiresInSeconds });
}
```

---

## IAM Policy (Principle of Least Privilege)

The backend IAM role should only have the permissions it actually needs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PresignedUrlGeneration",
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::your-bucket-name/users/*"
    },
    {
      "Sid": "ListBucketForValidation",
      "Effect": "Allow",
      "Action": ["s3:HeadObject"],
      "Resource": "arn:aws:s3:::your-bucket-name/*"
    }
  ]
}
```

Never give the backend (or anyone) `s3:*` or access to `*` resources.

---

## Bucket Configuration (Secure Defaults)

```hcl
# Terraform: block all public access
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle: auto-delete temp/unconfirmed uploads after 24h
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  rule {
    id     = "cleanup-temp-uploads"
    status = "Enabled"
    filter { prefix = "temp/" }
    expiration { days = 1 }
  }
}
```

---

## CloudFront (CDN for public assets only)

If you have public assets (e.g., product images), put CloudFront in front. Never expose S3 directly.

```typescript
// For public CDN assets, construct CDN URL instead of presigned URL
const cdnUrl = `https://${process.env.CLOUDFRONT_DOMAIN}/${key}`;
```

For private assets served via CloudFront, use **CloudFront Signed URLs** (not S3 presigned URLs).

---

## File Validation After Upload

After the client signals upload complete, validate the object:

```typescript
import { HeadObjectCommand } from '@aws-sdk/client-s3';

async function confirmUpload(key: string, expectedMaxBytes: number, userId: string) {
  const head = await s3.send(new HeadObjectCommand({
    Bucket: process.env.S3_BUCKET,
    Key: key,
  }));

  if (!head.ContentLength || head.ContentLength > expectedMaxBytes) {
    await s3.send(new DeleteObjectCommand({ Bucket: process.env.S3_BUCKET, Key: key }));
    throw new Error('File exceeds size limit');
  }

  // Optionally: trigger async virus scan via SNS/Lambda
}
```
