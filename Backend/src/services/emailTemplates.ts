/**
 * Templates HTML dos emails transacionais de reserva.
 * Design: HTML inline, sem imagens externas, compatível com major email clients.
 */

// ── Helpers ───────────────────────────────────────────────────────────────────

function esc(v: string | number | null | undefined): string {
  if (v === null || v === undefined) return '';
  return String(v)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function fmtBRL(valor: string | number): string {
  const n = typeof valor === 'number' ? valor : parseFloat(valor);
  return `R$ ${n.toFixed(2).replace('.', ',')}`;
}

function fmtDate(value: string | Date): string {
  // Driver `pg` retorna colunas DATE como Date object; API de reserva guest
  // envia string ISO. Suportamos ambos.
  const iso = value instanceof Date
    ? value.toISOString()
    : String(value ?? '');
  if (iso.length < 10) return String(value ?? '');
  const d = iso.slice(0, 10).split('-');
  return `${d[2]}/${d[1]}/${d[0]}`;
}

function wrap(title: string, bodyHtml: string): string {
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="utf-8"><title>${esc(title)}</title></head>
<body style="margin:0;padding:0;background:#F4F4F4;font-family:Arial,Helvetica,sans-serif;color:#182541;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:24px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0" style="background:#FFFFFF;border-radius:12px;overflow:hidden;">
        <tr><td style="background:#182541;color:#FFFFFF;padding:20px 24px;font-size:18px;font-weight:700;">
          ReservAqui
        </td></tr>
        <tr><td style="padding:24px;font-size:14px;line-height:1.6;">
          ${bodyHtml}
        </td></tr>
        <tr><td style="padding:16px 24px;background:#F4F4F4;color:#6B7280;font-size:11px;text-align:center;">
          Este é um email automático. Em caso de dúvida, responda esta mensagem.
        </td></tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}

// ── Inputs ───────────────────────────────────────────────────────────────────

export interface ReservaResumo {
  nomeHotel:     string;
  tipoQuarto:    string;
  dataCheckin:   string | Date;
  dataCheckout:  string | Date;
  numHospedes:   number;
  valorTotal:    string | number;
}

export interface ReservaPendenteInput {
  nomeHospede:    string;
  codigoPublico:  string;
  pagamentoUrl:   string;
  resumo:         ReservaResumo;
  expiresAt?:     string | null; // ISO timestamp (WPP)
}

export interface ReservaConfirmadaInput {
  nomeHospede:    string;
  codigoPublico:  string;
  ticketUrl:      string;
  resumo:         ReservaResumo;
}

export interface ReservaExpiradaInput {
  nomeHospede:    string;
  codigoPublico:  string;
  nomeHotel:      string;
}

// ── Templates ─────────────────────────────────────────────────────────────────

function resumoTable(r: ReservaResumo): string {
  return `
    <table width="100%" cellpadding="6" cellspacing="0" style="border-collapse:collapse;margin:12px 0;font-size:13px;">
      <tr><td style="color:#6B7280;">Hotel</td><td><strong>${esc(r.nomeHotel)}</strong></td></tr>
      <tr><td style="color:#6B7280;">Quarto</td><td>${esc(r.tipoQuarto)}</td></tr>
      <tr><td style="color:#6B7280;">Check-in</td><td>${esc(fmtDate(r.dataCheckin))}</td></tr>
      <tr><td style="color:#6B7280;">Check-out</td><td>${esc(fmtDate(r.dataCheckout))}</td></tr>
      <tr><td style="color:#6B7280;">Hóspedes</td><td>${esc(r.numHospedes)}</td></tr>
      <tr><td style="color:#6B7280;">Total</td><td><strong>${esc(fmtBRL(r.valorTotal))}</strong></td></tr>
    </table>`;
}

function button(label: string, url: string, bg = '#1B4AA0'): string {
  return `<a href="${esc(url)}"
           style="display:inline-block;background:${bg};color:#FFFFFF;text-decoration:none;
                  padding:12px 24px;border-radius:8px;font-weight:700;font-size:14px;">
    ${esc(label)}
  </a>`;
}

export function reservaPendentePagamentoTemplate(input: ReservaPendenteInput): { subject: string; html: string } {
  const expiraStr = input.expiresAt
    ? `<p style="color:#C0392B;font-size:13px;"><strong>⚠ O link expira em 30 minutos.</strong></p>`
    : '';

  const html = wrap(
    'Reserva pendente de pagamento',
    `<h2 style="margin:0 0 8px;font-size:18px;">Olá, ${esc(input.nomeHospede)}!</h2>
     <p>Sua reserva foi recebida e está aguardando pagamento para ser confirmada.</p>
     ${resumoTable(input.resumo)}
     <p>Para concluir, clique no botão abaixo:</p>
     <p style="margin:20px 0;">${button('Pagar agora', input.pagamentoUrl)}</p>
     ${expiraStr}
     <p style="color:#6B7280;font-size:12px;">Código da reserva: <strong>${esc(input.codigoPublico)}</strong></p>`
  );

  return {
    subject: `Reserva em ${input.resumo.nomeHotel} — pagamento pendente`,
    html,
  };
}

export function reservaConfirmadaTemplate(input: ReservaConfirmadaInput): { subject: string; html: string } {
  const html = wrap(
    'Reserva confirmada',
    `<h2 style="margin:0 0 8px;font-size:18px;color:#1E7A1E;">Reserva confirmada!</h2>
     <p>Olá, ${esc(input.nomeHospede)}. Seu pagamento foi aprovado e a sua reserva está confirmada.</p>
     ${resumoTable(input.resumo)}
     <p>Acesse o ticket da sua reserva a qualquer momento:</p>
     <p style="margin:20px 0;">${button('Ver meu ticket', input.ticketUrl, '#1E7A1E')}</p>
     <p style="color:#6B7280;font-size:12px;">Código da reserva: <strong>${esc(input.codigoPublico)}</strong></p>
     <p style="color:#6B7280;font-size:12px;">Mantenha este email — ele serve como voucher.</p>`
  );

  return {
    subject: `Reserva confirmada — ${input.resumo.nomeHotel}`,
    html,
  };
}

export function reservaExpiradaTemplate(input: ReservaExpiradaInput): { subject: string; html: string } {
  const html = wrap(
    'Reserva expirada',
    `<h2 style="margin:0 0 8px;font-size:18px;color:#C0392B;">Link de pagamento expirado</h2>
     <p>Olá, ${esc(input.nomeHospede)}.</p>
     <p>O tempo para concluir o pagamento da sua reserva em <strong>${esc(input.nomeHotel)}</strong>
        foi atingido e a reserva foi automaticamente cancelada.</p>
     <p>Se ainda quiser reservar, é só iniciar um novo pedido pelo app ou pelo nosso WhatsApp.</p>
     <p style="color:#6B7280;font-size:12px;">Código da reserva cancelada: <strong>${esc(input.codigoPublico)}</strong></p>`
  );

  return {
    subject: `Reserva expirada — ${input.nomeHotel}`,
    html,
  };
}
