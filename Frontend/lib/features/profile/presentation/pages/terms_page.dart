import 'package:flutter/material.dart';
import '../../../../core/utils/breakpoints.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: Breakpoints.isDesktop(context) ? null : const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Termos de Uso',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color.onSurface)),
            const SizedBox(height: 4),
            Text('Última atualização: maio de 2025',
                style: TextStyle(fontSize: 12, color: color.onSurfaceVariant)),
            const SizedBox(height: 24),
            _section(context,
                title: '1. Aceitação dos Termos',
                body:
                    'Ao acessar ou utilizar o aplicativo ReservAqui, você declara ter lido, '
                    'compreendido e concordado com estes Termos de Uso. Caso não concorde com '
                    'qualquer disposição aqui prevista, recomendamos que não utilize o serviço. '
                    'O uso continuado do aplicativo após alterações publicadas constitui '
                    'aceitação automática dos novos termos.'),
            _section(context,
                title: '2. Descrição do Serviço',
                body:
                    'O ReservAqui é uma plataforma digital que conecta hóspedes e anfitriões, '
                    'permitindo a busca, visualização e reserva de acomodações. A plataforma '
                    'atua como intermediária e não é responsável pela qualidade, segurança ou '
                    'legalidade das acomodações oferecidas pelos anfitriões cadastrados.'),
            _section(context,
                title: '3. Cadastro e Conta',
                body:
                    'Para utilizar os recursos completos do ReservAqui, é necessário criar uma '
                    'conta com informações verdadeiras e atualizadas. Você é o único responsável '
                    'pela confidencialidade de sua senha e por todas as atividades realizadas em '
                    'sua conta. Em caso de uso não autorizado, notifique imediatamente o suporte.'),
            _section(context,
                title: '4. Reservas',
                body:
                    'Ao realizar uma reserva, você faz uma solicitação formal ao anfitrião, '
                    'que poderá aceitá-la ou recusá-la. A confirmação da reserva só ocorre após '
                    'a aprovação do anfitrião e a conclusão do pagamento. Datas e valores '
                    'exibidos no aplicativo estão sujeitos à disponibilidade em tempo real.'),
            _section(context,
                title: '5. Pagamentos',
                body:
                    'Os pagamentos são processados por meio de gateways de pagamento seguros '
                    'e certificados. O ReservAqui não armazena dados de cartão de crédito. '
                    'Ao confirmar o pagamento, você autoriza a cobrança do valor total da '
                    'reserva, incluindo eventuais taxas de serviço indicadas no resumo de compra.'),
            _section(context,
                title: '6. Cancelamentos e Reembolsos',
                body:
                    'As políticas de cancelamento variam por acomodação e são definidas pelo '
                    'anfitrião. Antes de confirmar, revise a política aplicável exibida na '
                    'página da acomodação. Reembolsos, quando cabíveis, são processados no '
                    'prazo de até 10 dias úteis, podendo variar conforme a instituição financeira.'),
            _section(context,
                title: '7. Responsabilidades do Usuário',
                body:
                    'O usuário compromete-se a utilizar o ReservAqui somente para fins lícitos, '
                    'a não fornecer informações falsas, a não realizar reservas fraudulentas e '
                    'a tratar anfitriões e demais usuários com respeito. Violações poderão '
                    'resultar na suspensão ou exclusão permanente da conta, sem prejuízo de '
                    'medidas legais cabíveis.'),
            _section(context,
                title: '8. Limitação de Responsabilidade',
                body:
                    'O ReservAqui não se responsabiliza por danos diretos, indiretos ou '
                    'consequenciais decorrentes do uso ou da impossibilidade de uso do serviço, '
                    'por falhas nas acomodações ou por condutas de anfitriões ou hóspedes. '
                    'A responsabilidade máxima da plataforma perante o usuário fica limitada '
                    'ao valor pago na reserva em questão.'),
            _section(context,
                title: '9. Propriedade Intelectual',
                body:
                    'Todo o conteúdo do aplicativo — incluindo marca, logotipo, design, '
                    'textos e funcionalidades — é de propriedade exclusiva do ReservAqui ou '
                    'de seus licenciadores. É vedada a reprodução, distribuição ou modificação '
                    'sem autorização expressa e por escrito.'),
            _section(context,
                title: '10. Alterações nos Termos',
                body:
                    'Estes Termos podem ser atualizados periodicamente. Notificações sobre '
                    'mudanças relevantes serão enviadas pelo aplicativo ou por e-mail. '
                    'Recomendamos revisar os Termos regularmente.'),
            _section(context,
                title: '11. Lei Aplicável e Foro',
                body:
                    'Estes Termos são regidos pelas leis da República Federativa do Brasil. '
                    'Fica eleito o foro da comarca de São Paulo/SP para dirimir quaisquer '
                    'disputas decorrentes deste instrumento, com renúncia a qualquer outro, '
                    'por mais privilegiado que seja.'),
            const SizedBox(height: 16),
            Text('Em caso de dúvidas, entre em contato: reserv.aqui.123@gmail.com',
                style: TextStyle(fontSize: 13, color: color.onSurfaceVariant, height: 1.5)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, required String body}) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color.onSurface)),
          const SizedBox(height: 6),
          Text(body,
              style: TextStyle(fontSize: 14, color: color.onSurface, height: 1.6)),
        ],
      ),
    );
  }
}
