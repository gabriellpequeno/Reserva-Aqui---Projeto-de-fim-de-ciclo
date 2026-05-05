/**
 * Script utilitário para validar a configuração SMTP.
 * Uso:   npx ts-node src/scripts/testEmail.ts seu-email@example.com
 * Envia os 3 templates — se algum não chegar, confira o SMTP_* no .env.
 */
import 'dotenv/config';
import { sendEmail } from '../services/email.service';
import {
  reservaPendentePagamentoTemplate,
  reservaConfirmadaTemplate,
  reservaExpiradaTemplate,
} from '../services/emailTemplates';

async function main(): Promise<void> {
  const to = process.argv[2];
  if (!to) {
    console.error('Uso: npx ts-node src/scripts/testEmail.ts <email>');
    process.exit(1);
  }

  const resumo = {
    nomeHotel:    'Hotel Demo Reservaqui',
    tipoQuarto:   'Suíte Luxo',
    dataCheckin:  '2026-07-10',
    dataCheckout: '2026-07-15',
    numHospedes:  2,
    valorTotal:   1250.0,
  };

  const pendente = reservaPendentePagamentoTemplate({
    nomeHospede:   'Fulana de Tal',
    codigoPublico: 'r-demo123',
    pagamentoUrl:  `${process.env.FRONTEND_URL ?? 'http://localhost:8080'}/pagamento/r-demo123/1`,
    resumo,
    expiresAt:     new Date(Date.now() + 30 * 60 * 1000).toISOString(),
  });

  const confirmada = reservaConfirmadaTemplate({
    nomeHospede:   'Fulana de Tal',
    codigoPublico: 'r-demo123',
    ticketUrl:     `${process.env.FRONTEND_URL ?? 'http://localhost:8080'}/reservas/r-demo123`,
    resumo,
  });

  const expirada = reservaExpiradaTemplate({
    nomeHospede:   'Fulana de Tal',
    codigoPublico: 'r-demo123',
    nomeHotel:     resumo.nomeHotel,
  });

  console.log(`Enviando 3 emails de teste para ${to}...`);
  await sendEmail({ to, ...pendente });
  await sendEmail({ to, ...confirmada });
  await sendEmail({ to, ...expirada });
  console.log('OK — se SMTP estiver configurado, os 3 emails devem chegar.');
}

main().catch((err) => {
  console.error('Falha no teste:', err);
  process.exit(1);
});
