import { Router, Request, Response, NextFunction } from 'express';
import multer from 'multer';
import { imageUpload } from '../middlewares/imageUpload';
import { policyUpload, POLICY_ALLOWED_EXTENSIONS, POLICY_MAX_FILE_SIZE_BYTES } from '../middlewares/policyUpload';
import { hotelGuard } from '../middlewares/hotelGuard';
import {
  uploadHotelCover,
  deleteHotelCover,
  serveHotelCover,
  listHotelCovers,
  uploadRoomPhoto,
  deleteRoomPhoto,
  serveRoomPhoto,
  listRoomPhotos,
} from '../controllers/upload.controller';
import { uploadHotelPolicy, getHotelPolicy } from '../controllers/policyUpload.controller';

const router = Router();

const MAX_MB = Math.round(POLICY_MAX_FILE_SIZE_BYTES / (1024 * 1024));
const ALLOWED_EXTS = POLICY_ALLOWED_EXTENSIONS.join(', ');

function handlePolicyUpload(req: Request, res: Response, next: NextFunction): void {
  policyUpload.single('policy')(req, res, (err) => {
    if (!err) { next(); return; }

    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        res.status(422).json({
          error: `Arquivo muito grande. O limite é ${MAX_MB} MB.`,
        });
        return;
      }
      res.status(422).json({ error: `Erro no upload: ${err.message}` });
      return;
    }

    // Erros do fileFilter (tipo/extensão não permitidos)
    res.status(422).json({
      error: (err as Error).message ||
        `Tipo não permitido. Envie um arquivo ${ALLOWED_EXTS} com até ${MAX_MB} MB.`,
    });
  });
}

// ── Hotel Cover Photos ────────────────────────────────────────────────────────
// GET    /hotels/:hotel_id/cover               → lista todas as fotos de capa (opcionalmente filtrar por ?orientacao=)
// GET    /hotels/:hotel_id/cover/:foto_id      → serve o arquivo de imagem (público)
// POST   /hotels/:hotel_id/cover               → upload de nova foto de capa (requer auth anfitriao)
// DELETE /hotels/:hotel_id/cover/:foto_id      → remove uma foto de capa (requer auth anfitriao)

router.get('/hotels/:hotel_id/cover', listHotelCovers);
router.get('/hotels/:hotel_id/cover/:foto_id', serveHotelCover);
router.post('/hotels/:hotel_id/cover', hotelGuard, imageUpload.single('foto'), uploadHotelCover);
router.delete('/hotels/:hotel_id/cover/:foto_id', hotelGuard, deleteHotelCover);

// ── Room Photos ───────────────────────────────────────────────────────────────
// GET    /hotels/:hotel_id/rooms/:quarto_id               → lista fotos do quarto
// GET    /hotels/:hotel_id/rooms/:quarto_id/:foto_id      → serve o arquivo (público)
// POST   /hotels/:hotel_id/rooms/:quarto_id               → upload de nova foto do quarto (requer auth anfitriao)
// DELETE /hotels/:hotel_id/rooms/:quarto_id/:foto_id      → remove foto do quarto (requer auth anfitriao)

router.get('/hotels/:hotel_id/rooms/:quarto_id', listRoomPhotos);
router.get('/hotels/:hotel_id/rooms/:quarto_id/:foto_id', serveRoomPhoto);
router.post('/hotels/:hotel_id/rooms/:quarto_id', hotelGuard, imageUpload.single('foto'), uploadRoomPhoto);
router.delete('/hotels/:hotel_id/rooms/:quarto_id/:foto_id', hotelGuard, deleteRoomPhoto);

// ── Hotel Policy Document ─────────────────────────────────────────────────────
// GET  /hotels/:hotel_id/policy  → metadados da política atual (nome + data)
// POST /hotels/:hotel_id/policy  → upload/substituição do documento de política

router.get('/hotels/:hotel_id/policy', hotelGuard, getHotelPolicy);
router.post('/hotels/:hotel_id/policy', hotelGuard, handlePolicyUpload, uploadHotelPolicy);

export default router;
