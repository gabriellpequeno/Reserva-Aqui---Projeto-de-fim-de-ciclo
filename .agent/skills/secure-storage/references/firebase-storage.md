# Firebase Storage — Deep Dive Reference

## Overview

Firebase Storage is Google Cloud Storage with a Firebase-integrated access control layer (Security Rules)
and a client SDK that handles chunked uploads, retries, and progress events. The backend uses the
`@google-cloud/storage` or `firebase-admin` SDK.

---

## Upload Patterns

### Pattern A — Client SDK with Security Rules (simple apps)

The Flutter/web client uploads directly using the Firebase client SDK. Security Rules enforce who can write.

```dart
// Flutter: client uploads directly
final ref = FirebaseStorage.instance.ref('users/$userId/avatar.jpg');
await ref.putFile(file);
final url = await ref.getDownloadURL();
```

**Pros:** Simple, no backend needed.  
**Cons:** Client SDK must be initialized with Firebase config (acceptable); all authorization must be in
Security Rules (can become complex).

### Pattern B — Backend-generated Upload Token (recommended for production)

The backend generates a **signed upload URL** and returns it to the client. The client uploads directly to GCS.
No file bytes pass through the backend.

```typescript
// Node.js backend
import { getStorage } from 'firebase-admin/storage';

export async function generateUploadUrl(userId: string, filename: string) {
  const bucket = getStorage().bucket();
  const objectPath = `users/${userId}/${crypto.randomUUID()}`; // UUID, not user filename

  const [url] = await bucket.file(objectPath).getSignedUrl({
    version: 'v4',
    action: 'write',
    expires: Date.now() + 15 * 60 * 1000, // 15 minutes
    contentType: 'image/jpeg',             // lock content type
  });

  return { uploadUrl: url, storagePath: objectPath };
}
```

```typescript
// After upload completes, generate a read URL (does NOT use public download URL)
export async function generateReadUrl(storagePath: string) {
  const bucket = getStorage().bucket();
  const [url] = await bucket.file(storagePath).getSignedUrl({
    version: 'v4',
    action: 'read',
    expires: Date.now() + 60 * 60 * 1000, // 1 hour
  });
  return url;
}
```

---

## Security Rules

Security Rules are the GCS-level enforcement layer. They run before any read/write reaches the bucket.

### Public profile images (read-public, write-owner)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // User avatars: anyone can read, only owner can write
    match /users/{userId}/avatar {
      allow read: if true;
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024       // 5 MB max
                   && request.resource.contentType.matches('image/.*');
    }

    // All other paths: deny by default
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### Fully private files (multi-tenant)

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // tenants/{tenantId}/files/{fileId}
    match /tenants/{tenantId}/{allFiles=**} {
      // Only authenticated users whose tenantId claim matches
      allow read, write: if request.auth != null
                         && request.auth.token.tenantId == tenantId;
    }

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

> Set custom claims via `firebase-admin` after creating the user:
> ```typescript
> await admin.auth().setCustomUserClaims(uid, { tenantId: 'acme-corp' });
> ```

---

## Storing File References in the Database

Never store the public download URL — it's permanent and cannot be revoked. Store the storage path.

```sql
-- PostgreSQL: store storage path, not URL
ALTER TABLE user_profiles
  ADD COLUMN avatar_storage_path TEXT; -- e.g. 'users/uid-123/a1b2c3d4'
```

Generate the signed URL at query time (or cache it short-term with Redis):

```typescript
// In your profile resolver / service
const avatarUrl = profile.avatar_storage_path
  ? await generateReadUrl(profile.avatar_storage_path)
  : null;
```

---

## File Validation (backend-side, before saving to DB)

After upload completes (the client signals "done"), validate on the backend before trusting:

```typescript
import { getStorage } from 'firebase-admin/storage';
import FileType from 'file-type';

async function validateUploadedFile(storagePath: string) {
  const bucket = getStorage().bucket();
  const file = bucket.file(storagePath);

  const [metadata] = await file.getMetadata();
  const contentType = metadata.contentType;

  // Re-download first few bytes to check magic bytes (MIME sniffing)
  const [buffer] = await file.download({ start: 0, end: 12 });
  const detected = await FileType.fromBuffer(buffer);

  const allowed = ['image/jpeg', 'image/png', 'image/webp'];
  if (!detected || !allowed.includes(detected.mime)) {
    await file.delete(); // reject and clean up
    throw new Error('Invalid file type');
  }
}
```

---

## Cleanup — Deleting Files

Always delete the GCS object when the database record is deleted:

```typescript
async function deleteUserAvatar(userId: string, storagePath: string) {
  const bucket = getStorage().bucket();
  await bucket.file(storagePath).delete({ ignoreNotFound: true });
  // then delete/update DB record
}
```

Use Firebase Cloud Functions triggers (`storage.object().onDelete`) for cascading cleanup if needed.
