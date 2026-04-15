import express from 'express';
import dotenv from 'dotenv';
import usuarioRoutes   from './routes/usuario.routes';
import anfitriaoRoutes from './routes/anfitriao.routes';
import catalogoRoutes      from './routes/catalogo.routes';
import configuracaoRoutes  from './routes/configuracao.routes';
import uploadRoutes    from './routes/upload.routes';

// Carrega as variáveis de ambiente
dotenv.config();

const app = express();

app.use(express.json());

// Rota padrão do .env
const API_PREFIX = process.env.API_PREFIX || '/api';

// Rotas do sistema
app.use(`${API_PREFIX}/usuarios`, usuarioRoutes);
app.use(`${API_PREFIX}/hotel`,    anfitriaoRoutes);
app.use(`${API_PREFIX}/hotel`,    catalogoRoutes);
app.use(`${API_PREFIX}/hotel`,    configuracaoRoutes);
app.use(`${API_PREFIX}/uploads`,  uploadRoutes);

// Exporta e/ou inicia o servidor
const PORT = process.env.PORT || 3000;

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
    console.log(`Rota padrão (API_PREFIX): ${API_PREFIX}`);
  });
}

export default app;
