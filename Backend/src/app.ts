import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import usuarioRoutes   from './routes/usuario.routes';
import anfitriaoRoutes from './routes/anfitriao.routes';
import catalogoRoutes      from './routes/catalogo.routes';
import configuracaoRoutes    from './routes/configuracao.routes';
import categoriaQuartoRoutes from './routes/categoriaQuarto.routes';
import quartoRoutes          from './routes/quarto.routes';
import uploadRoutes    from './routes/upload.routes';
import {
  hotelReservaRouter,
  usuarioReservaRouter,
  publicReservaRouter,
} from './routes/reserva.routes';
import {
  usuarioAvaliacaoRouter,
  publicAvaliacaoRouter,
} from './routes/avaliacao.routes';
import dispositivoFcmRoutes    from './routes/dispositivoFcm.routes';
import notificacaoHotelRoutes  from './routes/notificacaoHotel.routes';
import {
  hotelPagamentoRouter,
  webhookPagamentoRouter,
  publicPagamentoRouter,
} from './routes/pagamentoReserva.routes';
import saldoRoutes from './routes/saldo.routes';
import whatsappRoutes from './routes/whatsapp.routes';
import searchRoomRoutes from './routes/searchRoom.routes';
import adminRoutes from './routes/admin.routes';
import {
  hostDashboardRouter,
  adminDashboardRouter,
} from './routes/dashboard.routes';
import chatRoutes from './routes/chat.routes';
import { startPaymentExpirationJob } from './services/paymentExpiration.job';

const app = express();

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());

// Rota padrão do .env
const API_PREFIX = process.env.API_PREFIX || '/api';

// Rotas do sistema
app.use(`${API_PREFIX}/usuarios`, usuarioRoutes);
app.use(`${API_PREFIX}/hotel`,    anfitriaoRoutes);
app.use(`${API_PREFIX}/hotel`,    catalogoRoutes);
app.use(`${API_PREFIX}/hotel`,    configuracaoRoutes);
app.use(`${API_PREFIX}/hotel`,    categoriaQuartoRoutes);
app.use(`${API_PREFIX}/hotel`,    quartoRoutes);
app.use(`${API_PREFIX}/uploads`,  uploadRoutes);
app.use(`${API_PREFIX}/hotel/reservas`,    hotelReservaRouter);
app.use(`${API_PREFIX}/usuarios/reservas`, usuarioReservaRouter);
app.use(`${API_PREFIX}/reservas`,          publicReservaRouter);
app.use(`${API_PREFIX}/usuarios/avaliacoes`,       usuarioAvaliacaoRouter);
app.use(`${API_PREFIX}/hotel/:hotel_id/avaliacoes`, publicAvaliacaoRouter);
app.use(`${API_PREFIX}/dispositivos-fcm`,           dispositivoFcmRoutes);
app.use(`${API_PREFIX}/hotel/notificacoes`,                      notificacaoHotelRoutes);
app.use(`${API_PREFIX}/hotel/reservas/:reserva_id/pagamentos`,    hotelPagamentoRouter);
app.use(`${API_PREFIX}/pagamentos/webhook`,                       webhookPagamentoRouter);
app.use(`${API_PREFIX}/reservas/:codigo_publico/pagamentos`,      publicPagamentoRouter);
app.use(`${API_PREFIX}/hotel`,                                    saldoRoutes);
app.use(`${API_PREFIX}/whatsapp`,                                 whatsappRoutes);
app.use(`${API_PREFIX}/quartos`, searchRoomRoutes);
app.use(`${API_PREFIX}/admin`,   adminRoutes);
app.use(`${API_PREFIX}/host/dashboard`,  hostDashboardRouter);
app.use(`${API_PREFIX}/admin/dashboard`, adminDashboardRouter);
app.use(`${API_PREFIX}/chat`,    chatRoutes);

// Exporta e/ou inicia o servidor
const PORT = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
    console.log(`Rota padrão (API_PREFIX): ${API_PREFIX}`);
  });
  startPaymentExpirationJob();
}

export default app;
