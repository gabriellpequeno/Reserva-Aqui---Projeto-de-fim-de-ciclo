import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_app_bar.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const CustomAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Política de Privacidade',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color.onSurface)),
            const SizedBox(height: 4),
            Text('Última atualização: maio de 2025',
                style: TextStyle(fontSize: 12, color: color.onSurfaceVariant)),
            const SizedBox(height: 24),
            _section(context,
                title: '1. Introdução',
                body:
                    'O ReservAqui respeita a sua privacidade e está comprometido com a '
                    'proteção dos seus dados pessoais, em conformidade com a Lei Geral de '
                    'Proteção de Dados (LGPD — Lei nº 13.709/2018) e demais normas aplicáveis. '
                    'Esta Política descreve quais dados coletamos, como os utilizamos e '
                    'quais são os seus direitos como titular.'),
            _section(context,
                title: '2. Dados Coletados',
                body:
                    'Coletamos as seguintes categorias de dados:\n\n'
                    '• Dados de cadastro: nome completo, e-mail, número de telefone e senha '
                    '(armazenada em formato criptografado).\n\n'
                    '• Dados de pagamento: processados diretamente pelo gateway de pagamento '
                    'parceiro; o ReservAqui não armazena números de cartão.\n\n'
                    '• Dados de uso: histórico de buscas, reservas, avaliações e interações '
                    'com o assistente virtual.\n\n'),
            _section(context,
                title: '3. Finalidade do Tratamento',
                body:
                    'Utilizamos seus dados para:\n\n'
                    '• Criar e gerenciar sua conta;\n'
                    '• Processar e confirmar reservas;\n'
                    '• Comunicar informações sobre reservas, promoções e atualizações do serviço;\n'
                    '• Personalizar a experiência no aplicativo;\n'
                    '• Garantir a segurança e prevenir fraudes;\n'
                    '• Cumprir obrigações legais e regulatórias.'),
            _section(context,
                title: '4. Compartilhamento de Dados',
                body:
                    'Seus dados poderão ser compartilhados com:\n\n'
                    '• Anfitriões, na medida necessária para a concretização da reserva;\n'
                    '• Parceiros de pagamento, para processamento de transações financeiras;\n'
                    '• Prestadores de serviços de tecnologia e infraestrutura, sob acordos '
                    'de confidencialidade;\n'
                    '• Autoridades competentes, quando exigido por lei ou ordem judicial.\n\n'
                    'Não vendemos nem cedemos seus dados a terceiros para fins comerciais '
                    'sem o seu consentimento explícito.'),
            _section(context,
                title: '5. Segurança dos Dados',
                body:
                    'Adotamos medidas técnicas e organizacionais adequadas para proteger '
                    'seus dados contra acesso não autorizado, perda, alteração ou divulgação '
                    'indevida. Entre as práticas adotadas estão criptografia em trânsito (TLS), '
                    'autenticação segura e controles de acesso internos baseados no princípio '
                    'do menor privilégio.'),
            _section(context,
                title: '6. Seus Direitos (LGPD)',
                body:
                    'Como titular de dados, você tem direito a:\n\n'
                    '• Confirmar a existência de tratamento;\n'
                    '• Acessar seus dados;\n'
                    '• Corrigir dados incompletos, inexatos ou desatualizados;\n'
                    '• Solicitar a anonimização, bloqueio ou eliminação de dados desnecessários;\n'
                    '• Revogar o consentimento a qualquer momento;\n'
                    '• Solicitar a portabilidade para outro serviço.\n\n'
                    'Para exercer qualquer desses direitos, entre em contato pelo e-mail '
                    'reserv.aqui.123@gmail.com'),
            _section(context,
                title: '7. Retenção de Dados',
                body:
                    'Seus dados são mantidos pelo tempo necessário para a prestação do '
                    'serviço ou para cumprimento de obrigações legais. Após o encerramento '
                    'da conta, os dados são excluídos ou anonimizados, salvo quando a '
                    'retenção for exigida por lei (ex.: dados fiscais, por 5 anos).'),
            _section(context,
                title: '8. Cookies e Tecnologias Similares',
                body:
                    'O aplicativo pode utilizar identificadores anônimos de sessão para '
                    'manter o estado de login e personalizar a experiência. Não utilizamos '
                    'rastreadores de terceiros para fins publicitários sem o seu consentimento.'),
            _section(context,
                title: '9. Alterações nesta Política',
                body:
                    'Esta Política pode ser atualizada periodicamente. Mudanças relevantes '
                    'serão comunicadas pelo aplicativo ou por e-mail com antecedência mínima '
                    'de 15 dias. O uso continuado do serviço após a data de vigência das '
                    'alterações implica aceitação da Política revisada.'),
            const SizedBox(height: 16),
            Text(
                'Controlador dos dados: ReservAqui Tecnologia Ltda.\n'
                'Encarregado (DPO): reserv.aqui.123@gmail.com',
                style: TextStyle(fontSize: 13, color: color.onSurfaceVariant, height: 1.6)),
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
