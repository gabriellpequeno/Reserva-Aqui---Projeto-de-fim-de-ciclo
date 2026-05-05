import nodemailer from 'nodemailer';
import type { Transporter } from 'nodemailer';

// ── Tipos ─────────────────────────────────────────────────────────────────────

export interface SendEmailInput {
  to:       string;
  subject:  string;
  html:     string;
  text?:    string;
}

// ── Transporter ──────────────────────────────────────────────────────────────
//
// Singleton com lazy-init. Se SMTP_HOST não estiver configurado, o serviço
// vira um no-op silencioso — fluxo de reserva não é bloqueado por falta de
// email. Em dev local sem SMTP, emails só aparecem como warn no console.

let _transporter: Transporter | null | undefined;

function getTransporter(): Transporter | null {
  if (_transporter !== undefined) return _transporter;

  const host = process.env.SMTP_HOST;
  if (!host) {
    console.warn('[email] SMTP_HOST não configurado — envios serão no-op.');
    _transporter = null;
    return null;
  }

  const port   = parseInt(process.env.SMTP_PORT ?? '587', 10);
  const secure = port === 465;

  console.log(`[email] init SMTP host=${host} port=${port} secure=${secure} user=${process.env.SMTP_USER ?? '(none)'}`);

  _transporter = nodemailer.createTransport({
    host,
    port,
    secure,
    auth: process.env.SMTP_USER
      ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS }
      : undefined,
  });

  // Verify assíncrono (não bloqueia) — mostra no log se autenticação funcionou
  _transporter.verify().then(
    () => console.log('[email] SMTP verify OK — autenticação aceita pelo servidor'),
    (err) => console.warn('[email] SMTP verify FALHOU:', (err as Error).message),
  );

  return _transporter;
}

/**
 * Resolve o FROM do envio. Regra: providers como Gmail rejeitam (ou reescrevem
 * silenciosamente, causando emails que não chegam) quando o FROM não bate com
 * o usuário autenticado. Se SMTP_FROM foi explicitamente configurado com um
 * domínio **diferente** do SMTP_USER, usamos o formato "Nome <SMTP_USER>"
 * preservando apenas o nome amigável.
 */
function resolveFromHeader(): string {
  const user     = process.env.SMTP_USER ?? '';
  const rawFrom  = process.env.SMTP_FROM ?? '';

  if (!user)    return rawFrom || 'ReservAqui <noreply@reservaqui.app>';
  if (!rawFrom) return user;

  // Extrai "Nome" de "Nome <email@...>" ou usa o valor todo
  const match = rawFrom.match(/^\s*(.+?)\s*<([^>]+)>\s*$/);
  if (!match) {
    // FROM é só email — se for diferente do user, reescreve pro user
    return rawFrom.trim() === user ? rawFrom : user;
  }
  const friendlyName = match[1];
  const fromEmail    = match[2];

  // Se domínio bate, mantém; se não, força o user autenticado como email
  if (fromEmail.toLowerCase() === user.toLowerCase()) return rawFrom;
  return `${friendlyName} <${user}>`;
}

// ── API Pública ───────────────────────────────────────────────────────────────

/**
 * Envia um email. Fire-and-forget seguro: erros são logados mas nunca propagam.
 * Chamadores devem usar .catch(() => {}) se quiserem ignorar a Promise.
 */
export async function sendEmail(input: SendEmailInput): Promise<void> {
  const transporter = getTransporter();

  if (!transporter) {
    console.warn(`[email] (no-op) Para ${input.to}: ${input.subject}`);
    return;
  }

  const from = resolveFromHeader();

  console.log(`[email] enviando from="${from}" to=${input.to} assunto="${input.subject}"`);
  try {
    const info = await transporter.sendMail({
      from,
      to:      input.to,
      subject: input.subject,
      html:    input.html,
      text:    input.text ?? stripHtml(input.html),
    });
    console.log(`[email] OK to=${input.to} messageId=${info.messageId} accepted=${JSON.stringify(info.accepted)} rejected=${JSON.stringify(info.rejected)} response="${info.response}"`);
  } catch (err) {
    console.warn(`[email] FALHA to=${input.to}:`, (err as Error).message);
    if ((err as Error).stack) console.warn((err as Error).stack);
  }
}

/** Strip simples de HTML para fallback do campo text/plain. */
function stripHtml(html: string): string {
  return html.replace(/<style[\s\S]*?<\/style>/gi, '')
             .replace(/<[^>]+>/g, '')
             .replace(/\s+/g, ' ')
             .trim();
}
