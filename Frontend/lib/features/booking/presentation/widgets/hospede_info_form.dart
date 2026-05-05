import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/phone_mask_formatter.dart';
import '../../../auth/utils/validators.dart';
import '../../domain/models/hospede_info.dart';

/// Formulário unificado dos dados do hóspede — exibido em qualquer checkout
/// (user autenticado ou guest). Quando `initialData` é passado, os campos
/// chegam pré-preenchidos e o usuário pode manter (reservar pra si) ou editar
/// (reservar pra terceiro).
class HospedeInfoForm extends StatefulWidget {
  final HospedeInfoFormData? initialData;
  final VoidCallback? onChanged;

  const HospedeInfoForm({
    super.key,
    this.initialData,
    this.onChanged,
  });

  @override
  State<HospedeInfoForm> createState() => HospedeInfoFormState();
}

class HospedeInfoFormState extends State<HospedeInfoForm> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _cpfCtrl;
  late final TextEditingController _telCtrl;

  final _cpfMask = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {'#': RegExp(r'\d')},
  );

  @override
  void initState() {
    super.initState();
    _nomeCtrl  = TextEditingController(text: widget.initialData?.nome  ?? '');
    _emailCtrl = TextEditingController(text: widget.initialData?.email ?? '');
    _cpfCtrl   = TextEditingController(text: _applyCpfMask(widget.initialData?.cpf));
    _telCtrl   = TextEditingController(text: _applyPhoneMask(widget.initialData?.telefone));
  }

  @override
  void didUpdateWidget(covariant HospedeInfoForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Async-arrived pre-fill: quando o parent só obtém os dados do user depois
    // do primeiro build, precisamos popular os controllers que nasceram vazios.
    // Critério: só sobrescrever campos que estão vazios — se o usuário já digitou
    // algo manualmente, respeitamos a entrada dele.
    final newData = widget.initialData;
    if (newData == null) return;
    if (newData == oldWidget.initialData) return;

    if (_nomeCtrl.text.isEmpty)  _nomeCtrl.text  = newData.nome;
    if (_emailCtrl.text.isEmpty) _emailCtrl.text = newData.email;
    if (_cpfCtrl.text.isEmpty)   _cpfCtrl.text   = _applyCpfMask(newData.cpf);
    if (_telCtrl.text.isEmpty)   _telCtrl.text   = _applyPhoneMask(newData.telefone);
  }

  String _applyCpfMask(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return raw;
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }

  String _applyPhoneMask(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length == 11) return '(${d.substring(0, 2)}) ${d.substring(2, 7)}-${d.substring(7)}';
    if (d.length == 10) return '(${d.substring(0, 2)}) ${d.substring(2, 6)}-${d.substring(6)}';
    return raw;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _cpfCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  /// Dispara validação. Retorna true se OK.
  bool validate() => formKey.currentState?.validate() ?? false;

  /// Retorna os dados com valores despmascarados.
  HospedeInfoFormData getData() {
    return HospedeInfoFormData(
      nome:     _nomeCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      cpf:      onlyDigits(_cpfCtrl.text),
      telefone: onlyDigits(_telCtrl.text),
    );
  }

  /// True se algum campo diverge do pré-preenchimento.
  bool get hasDiverged => getData().hasDivergedFrom(widget.initialData);

  @override
  Widget build(BuildContext context) {
    final showDivergenceHint =
        widget.initialData != null && hasDiverged;

    return Form(
      key: formKey,
      onChanged: widget.onChanged,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados do hóspede',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          if (showDivergenceHint)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColors.secondary),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reservando para outra pessoa',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const SizedBox(height: 8),
          _field(
            controller: _nomeCtrl,
            hint: 'Nome completo',
            keyboard: TextInputType.name,
            validator: validateNomeCompleto,
          ),
          const SizedBox(height: 10),
          _field(
            controller: _emailCtrl,
            hint: 'email@exemplo.com',
            keyboard: TextInputType.emailAddress,
            validator: validateEmail,
          ),
          const SizedBox(height: 10),
          _field(
            controller: _cpfCtrl,
            hint: 'CPF',
            keyboard: TextInputType.number,
            formatters: [_cpfMask],
            validator: validateCpf,
          ),
          const SizedBox(height: 10),
          _field(
            controller: _telCtrl,
            hint: '(DDD) número',
            keyboard: TextInputType.phone,
            formatters: [PhoneMaskFormatter()],
            validator: validateTelefoneBr,
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboard,
    required String? Function(String?) validator,
    List formatters = const [],
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      inputFormatters: formatters.isEmpty ? null : formatters.cast(),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 13, color: AppColors.primary),
    );
  }
}
