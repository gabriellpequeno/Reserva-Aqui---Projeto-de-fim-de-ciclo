import multer, { FileFilterCallback } from 'multer';
import path from 'path';
import os from 'os';
import { Request } from 'express';

// ── Configurações via ENV ─────────────────────────────────────────────────────
const MAX_SIZE_MB = parseFloat(process.env.UPLOAD_MAX_SIZE_MB || '10');
const MAX_FILE_SIZE_BYTES = MAX_SIZE_MB * 1024 * 1024;

const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const ALLOWED_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp'];

/**
 * Configuração do multer para uploads de imagem.
 *
 * - Arquivos ficam no diretório temporário do SO enquanto aguardam validação.
 * - O caller (controller) é responsável por mover ou deletar o arquivo temp.
 * - Validação de MIME e extensão dupla acontece aqui (camada 1).
 * - Validação por magic bytes acontece no controller (camada 2).
 */
export const imageUpload = multer({
  dest: path.join(os.tmpdir(), 'reservaqui-uploads'),
  limits: {
    fileSize: MAX_FILE_SIZE_BYTES,
    files: 1,
  },
  fileFilter: (_req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
    const ext = path.extname(file.originalname).toLowerCase();

    // Previne ataques de dupla extensão (ex: malware.php.jpg)
    const nameWithoutExt = path.basename(file.originalname, ext);
    if (ALLOWED_EXTENSIONS.some((e) => nameWithoutExt.endsWith(e))) {
      cb(new Error('Nome de arquivo inválido'));
      return;
    }

    if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
      cb(new Error(`Tipo de arquivo não permitido. Use: ${ALLOWED_MIME_TYPES.join(', ')}`));
      return;
    }

    if (!ALLOWED_EXTENSIONS.includes(ext)) {
      cb(new Error(`Extensão não permitida. Use: ${ALLOWED_EXTENSIONS.join(', ')}`));
      return;
    }

    cb(null, true);
  },
});

export { ALLOWED_EXTENSIONS, MAX_FILE_SIZE_BYTES };
