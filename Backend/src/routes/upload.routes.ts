import { Router } from 'express';
import { imageUpload } from '../middlewares/imageUpload';
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

const router = Router();

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

export default router;
