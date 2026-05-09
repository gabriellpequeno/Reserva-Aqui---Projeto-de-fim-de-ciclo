import multer, { FileFilterCallback } from 'multer';
import path from 'path';
import os from 'os';
import { Request } from 'express';

const MAX_SIZE_MB = parseFloat(process.env.UPLOAD_MAX_POLICY_SIZE_MB || '5');
const MAX_FILE_SIZE_BYTES = MAX_SIZE_MB * 1024 * 1024;

const ALLOWED_MIME_TYPES = [
  'application/pdf',
  'text/plain',
  'text/markdown',
  'text/x-markdown',
  'application/octet-stream', // .txt em alguns SOs reporta este MIME
];

const ALLOWED_EXTENSIONS = ['.pdf', '.txt', '.md'];

export const policyUpload = multer({
  dest: path.join(os.tmpdir(), 'reservaqui-policy-uploads'),
  limits: {
    fileSize: MAX_FILE_SIZE_BYTES,
    files: 1,
  },
  fileFilter: (_req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
    const ext = path.extname(file.originalname).toLowerCase();

    // Previne ataques de dupla extensão (ex: malware.pdf.js)
    const nameWithoutExt = path.basename(file.originalname, ext);
    if (ALLOWED_EXTENSIONS.some((e) => nameWithoutExt.endsWith(e))) {
      cb(new Error('Nome de arquivo inválido'));
      return;
    }

    const extOk  = ALLOWED_EXTENSIONS.includes(ext);
    const mimeOk = ALLOWED_MIME_TYPES.includes(file.mimetype);

    // Aceita se extensão for válida (MIME pode variar por SO)
    if (!extOk) {
      cb(new Error(`Tipo não permitido. Use: ${ALLOWED_EXTENSIONS.join(', ')}`));
      return;
    }

    // Rejeita somente se MIME for claramente hostil (ex: image/png com .pdf)
    if (!mimeOk && file.mimetype.startsWith('image/')) {
      cb(new Error('Tipo de arquivo não permitido'));
      return;
    }

    cb(null, true);
  },
});

export { ALLOWED_EXTENSIONS as POLICY_ALLOWED_EXTENSIONS, MAX_FILE_SIZE_BYTES as POLICY_MAX_FILE_SIZE_BYTES };
