import 'package:flutter/material.dart';
import '../../../../core/utils/breakpoints.dart';

void showTermsModal(BuildContext context) {
  if (Breakpoints.isDesktop(context)) {
    _showTermsDialog(context);
  } else {
    _showTermsBottomSheet(context);
  }
}

void _showTermsDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Termos e Condições',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
                child: const Text(_kTermsText, style: TextStyle(height: 1.6)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showTermsBottomSheet(BuildContext context) {
  final screenHeight = MediaQuery.sizeOf(context).height;
  final topPadding = MediaQuery.paddingOf(context).top;
  final bottomPadding = MediaQuery.paddingOf(context).bottom;
  final maxHeight = (screenHeight - topPadding) * 0.80;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: maxHeight),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[400],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Termos e Condições',
            style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
            child: const Text(_kTermsText, style: TextStyle(height: 1.6)),
          ),
        ),
      ],
    ),
  );
}

const String _kTermsText = '''
Última atualização: maio de 2025

Bem-vindo ao ReservAqui. Ao criar uma conta e utilizar nossa plataforma, você concorda com os seguintes Termos e Condições. Leia-os com atenção antes de prosseguir.

1. ACEITAÇÃO DOS TERMOS

Ao se cadastrar, o usuário declara ter lido, compreendido e aceito integralmente estes Termos e Condições, bem como nossa Política de Privacidade. Caso não concorde com qualquer disposição, não utilize nossos serviços.

2. ELEGIBILIDADE

O uso da plataforma é restrito a pessoas físicas com idade mínima de 18 (dezoito) anos. Ao se cadastrar, você declara que possui a idade mínima exigida e que as informações fornecidas são verdadeiras e completas.

3. CADASTRO E CONTA

O usuário é responsável por manter a confidencialidade de suas credenciais de acesso. Qualquer atividade realizada sob sua conta é de sua responsabilidade. Em caso de uso não autorizado, notifique imediatamente a plataforma pelo canal de suporte.

4. USO DA PLATAFORMA

A plataforma ReservAqui conecta hóspedes a estabelecimentos de hospedagem. O usuário se compromete a:
— Fornecer informações verídicas no cadastro e nas reservas;
— Utilizar a plataforma apenas para fins lícitos;
— Não tentar acessar sistemas, dados ou áreas restritas sem autorização.

5. RESERVAS E CANCELAMENTOS

As condições de reserva, incluindo políticas de cancelamento e reembolso, são definidas por cada estabelecimento. O ReservAqui atua como intermediário e não se responsabiliza por alterações unilaterais feitas pelos estabelecimentos, desde que devidamente informadas ao usuário.

6. PRIVACIDADE E DADOS PESSOAIS

O tratamento de dados pessoais segue as disposições da Lei Geral de Proteção de Dados (LGPD — Lei nº 13.709/2018). Coletamos apenas os dados necessários para a prestação dos serviços. Para mais detalhes, consulte nossa Política de Privacidade.

7. PROPRIEDADE INTELECTUAL

Todo o conteúdo da plataforma — incluindo marca, logotipo, layout, textos e funcionalidades — é de propriedade exclusiva do ReservAqui ou de seus licenciadores. É proibida a reprodução sem autorização prévia e expressa.

8. LIMITAÇÃO DE RESPONSABILIDADE

O ReservAqui não se responsabiliza por danos decorrentes de indisponibilidade temporária da plataforma, erros de informação fornecidos pelos estabelecimentos ou problemas na prestação dos serviços de hospedagem.

9. MODIFICAÇÕES DOS TERMOS

Reservamo-nos o direito de alterar estes Termos a qualquer momento. Alterações relevantes serão comunicadas aos usuários cadastrados. O uso continuado da plataforma após a notificação implica aceitação dos novos termos.

10. CONTATO

Em caso de dúvidas, entre em contato com nosso suporte pelo e-mail suporte@reservaqui.com.br.
''';
