import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/admin_account_status.dart';
import '../../domain/models/admin_hotel_model.dart';
import '../../domain/models/admin_user_model.dart';

/// Resultado da edição feita no bottom sheet.
///
/// `status` vem preenchido quando o admin mudou o status da conta; `dataPatch`
/// vem preenchido com as chaves (no formato esperado pelo backend) dos campos
/// que foram alterados. Ambos podem coexistir num mesmo save.
class AdminEditResult {
  final AdminAccountStatus? status;
  final Map<String, dynamic>? dataPatch;

  const AdminEditResult({this.status, this.dataPatch});

  bool get isEmpty => status == null && (dataPatch == null || dataPatch!.isEmpty);
}

/// Tipo de conta que o sheet está editando. Público porque integra a API
/// interna do widget (via construtor nomeado), mas consumidores usam os
/// factories `showForUser` / `showForHotel`.
enum AdminAccountKind { user, hotel }

/// Bottom sheet de edição de conta para o admin.
///
/// Permite alterar o status (radios) e os dados não-sensíveis do alvo,
/// em um único form. Campos mudam conforme `kind`.
///
/// Uso:
/// ```dart
/// final result = await AdminEditAccountSheet.showForUser(context: ..., user: u);
/// ```
class AdminEditAccountSheet extends StatefulWidget {
  final AdminAccountKind kind;
  final AdminUserModel? user;
  final AdminHotelModel? hotel;
  final List<AdminAccountStatus> allowedStatuses;
  final ScrollController scrollController;

  const AdminEditAccountSheet._({
    required this.kind,
    this.user,
    this.hotel,
    required this.allowedStatuses,
    required this.scrollController,
  });

  static Future<AdminEditResult?> showForUser({
    required BuildContext context,
    required AdminUserModel user,
  }) {
    return _show(
      context: context,
      builder: (controller) => AdminEditAccountSheet._(
        kind: AdminAccountKind.user,
        user: user,
        allowedStatuses: const [
          AdminAccountStatus.ativo,
          AdminAccountStatus.suspenso,
        ],
        scrollController: controller,
      ),
    );
  }

  static Future<AdminEditResult?> showForHotel({
    required BuildContext context,
    required AdminHotelModel hotel,
  }) {
    return _show(
      context: context,
      builder: (controller) => AdminEditAccountSheet._(
        kind: AdminAccountKind.hotel,
        hotel: hotel,
        allowedStatuses: const [
          AdminAccountStatus.ativo,
          AdminAccountStatus.inativo,
        ],
        scrollController: controller,
      ),
    );
  }

  static Future<AdminEditResult?> _show({
    required BuildContext context,
    required AdminEditAccountSheet Function(ScrollController) builder,
  }) {
    return showModalBottomSheet<AdminEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => builder(scrollController),
      ),
    );
  }

  @override
  State<AdminEditAccountSheet> createState() => _AdminEditAccountSheetState();
}

class _AdminEditAccountSheetState extends State<AdminEditAccountSheet> {
  late AdminAccountStatus _status;
  final _formKey = GlobalKey<FormState>();

  // Usuário
  TextEditingController? _userNome;
  TextEditingController? _userEmail;
  TextEditingController? _userTelefone;

  // Hotel
  TextEditingController? _hotelNome;
  TextEditingController? _hotelEmail;
  TextEditingController? _hotelTelefone;
  TextEditingController? _hotelDescricao;
  TextEditingController? _hotelCep;
  TextEditingController? _hotelUf;
  TextEditingController? _hotelCidade;
  TextEditingController? _hotelBairro;
  TextEditingController? _hotelRua;
  TextEditingController? _hotelNumero;
  TextEditingController? _hotelComplemento;

  @override
  void initState() {
    super.initState();
    if (widget.kind == AdminAccountKind.user) {
      final u = widget.user!;
      _status = u.status;
      _userNome     = TextEditingController(text: u.nome);
      _userEmail    = TextEditingController(text: u.email);
      _userTelefone = TextEditingController(text: u.telefone ?? '');
    } else {
      final h = widget.hotel!;
      _status = h.status;
      _hotelNome        = TextEditingController(text: h.nome);
      _hotelEmail       = TextEditingController(text: h.emailResponsavel);
      _hotelTelefone    = TextEditingController(text: h.telefone);
      _hotelDescricao   = TextEditingController(text: h.descricao ?? '');
      _hotelCep         = TextEditingController(text: h.cep);
      _hotelUf          = TextEditingController(text: h.uf);
      _hotelCidade      = TextEditingController(text: h.cidade);
      _hotelBairro      = TextEditingController(text: h.bairro);
      _hotelRua         = TextEditingController(text: h.rua);
      _hotelNumero      = TextEditingController(text: h.numero);
      _hotelComplemento = TextEditingController(text: h.complemento ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in [
      _userNome, _userEmail, _userTelefone,
      _hotelNome, _hotelEmail, _hotelTelefone, _hotelDescricao,
      _hotelCep, _hotelUf, _hotelCidade, _hotelBairro, _hotelRua,
      _hotelNumero, _hotelComplemento,
    ]) {
      c?.dispose();
    }
    super.dispose();
  }

  // ── Validators ────────────────────────────────────────────────────────────

  String? _validateRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
    final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim());
    return ok ? null : 'Email inválido';
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // telefone é opcional no user
    final ok = RegExp(r'^\(\d{2}\) \d{4,5}-\d{4}$').hasMatch(v.trim());
    return ok ? null : 'Formato esperado (XX) XXXXX-XXXX';
  }

  String? _validatePhoneRequired(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
    return _validatePhone(v);
  }

  String? _validateCep(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
    final digits = v.replaceAll(RegExp(r'\D'), '');
    return digits.length == 8 ? null : 'CEP deve ter 8 dígitos';
  }

  String? _validateUf(String? v) {
    if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
    return RegExp(r'^[A-Za-z]{2}$').hasMatch(v.trim())
        ? null
        : 'UF deve ter 2 letras';
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final patch = <String, dynamic>{};
    if (widget.kind == AdminAccountKind.user) {
      final u = widget.user!;
      _diff(patch, 'nome_completo',  _userNome!.text.trim(),      u.nome);
      _diff(patch, 'email',          _userEmail!.text.trim(),     u.email);
      _diff(patch, 'numero_celular', _userTelefone!.text.trim(),  u.telefone ?? '');
    } else {
      final h = widget.hotel!;
      _diff(patch, 'nome_hotel',  _hotelNome!.text.trim(),       h.nome);
      _diff(patch, 'email',       _hotelEmail!.text.trim(),      h.emailResponsavel);
      _diff(patch, 'telefone',    _hotelTelefone!.text.trim(),   h.telefone);
      _diff(patch, 'descricao',   _hotelDescricao!.text.trim(),  h.descricao ?? '');
      _diff(patch, 'cep',         _hotelCep!.text.trim(),        h.cep);
      _diff(patch, 'uf',          _hotelUf!.text.trim().toUpperCase(), h.uf);
      _diff(patch, 'cidade',      _hotelCidade!.text.trim(),     h.cidade);
      _diff(patch, 'bairro',      _hotelBairro!.text.trim(),     h.bairro);
      _diff(patch, 'rua',         _hotelRua!.text.trim(),        h.rua);
      _diff(patch, 'numero',      _hotelNumero!.text.trim(),     h.numero);
      _diff(patch, 'complemento', _hotelComplemento!.text.trim(), h.complemento ?? '');
    }

    final initialStatus = widget.kind == AdminAccountKind.user
        ? widget.user!.status
        : widget.hotel!.status;
    final statusChanged = _status != initialStatus;

    final result = AdminEditResult(
      status: statusChanged ? _status : null,
      dataPatch: patch.isEmpty ? null : patch,
    );
    if (result.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(result);
  }

  void _diff(Map<String, dynamic> patch, String key, String current, String initial) {
    if (current != initial) patch[key] = current;
  }

  String _labelFor(AdminAccountStatus s) {
    switch (s) {
      case AdminAccountStatus.ativo:
        return 'Ativo';
      case AdminAccountStatus.suspenso:
        return 'Suspenso';
      case AdminAccountStatus.inativo:
        return 'Inativo';
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scrollController = widget.scrollController;
    final title = widget.kind == AdminAccountKind.user ? 'Editar usuário' : 'Editar hotel';
    final subtitle = widget.kind == AdminAccountKind.user
        ? widget.user!.email
        : widget.hotel!.emailResponsavel;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.zero,
                children: [
                  _sectionTitle('Status da conta'),
                  ...widget.allowedStatuses.map(
                    (s) => RadioListTile<AdminAccountStatus>(
                      title: Text(_labelFor(s)),
                      value: s,
                      groupValue: _status,
                      activeColor: AppColors.secondary,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onChanged: (v) => setState(() => _status = v ?? _status),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionTitle('Dados'),
                  const SizedBox(height: 8),
                  if (widget.kind == AdminAccountKind.user)
                    ..._buildUserFields()
                  else
                    ..._buildHotelFields(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildUserFields() {
    return [
      _field(
        controller: _userNome!,
        label: 'Nome completo',
        validator: _validateRequired,
      ),
      _field(
        controller: _userEmail!,
        label: 'Email',
        keyboardType: TextInputType.emailAddress,
        validator: _validateEmail,
      ),
      _field(
        controller: _userTelefone!,
        label: 'Telefone',
        keyboardType: TextInputType.phone,
        inputFormatters: [_BrazilianPhoneFormatter()],
        validator: _validatePhone,
      ),
    ];
  }

  List<Widget> _buildHotelFields() {
    return [
      _field(
        controller: _hotelNome!,
        label: 'Nome do hotel',
        validator: _validateRequired,
      ),
      _field(
        controller: _hotelEmail!,
        label: 'Email do responsável',
        keyboardType: TextInputType.emailAddress,
        validator: _validateEmail,
      ),
      _field(
        controller: _hotelTelefone!,
        label: 'Telefone',
        keyboardType: TextInputType.phone,
        inputFormatters: [_BrazilianPhoneFormatter()],
        validator: _validatePhoneRequired,
      ),
      _field(
        controller: _hotelDescricao!,
        label: 'Descrição',
        maxLines: 3,
      ),
      _field(
        controller: _hotelCep!,
        label: 'CEP',
        keyboardType: TextInputType.number,
        validator: _validateCep,
      ),
      _field(
        controller: _hotelUf!,
        label: 'UF',
        maxLength: 2,
        textCapitalization: TextCapitalization.characters,
        validator: _validateUf,
      ),
      _field(
        controller: _hotelCidade!,
        label: 'Cidade',
        validator: _validateRequired,
      ),
      _field(
        controller: _hotelBairro!,
        label: 'Bairro',
        validator: _validateRequired,
      ),
      _field(
        controller: _hotelRua!,
        label: 'Rua',
        validator: _validateRequired,
      ),
      _field(
        controller: _hotelNumero!,
        label: 'Número',
        validator: _validateRequired,
      ),
      _field(
        controller: _hotelComplemento!,
        label: 'Complemento (opcional)',
      ),
    ];
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 4),
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

/// Formatador que aplica a máscara brasileira (XX) XXXX-XXXX / (XX) XXXXX-XXXX
/// conforme o usuário digita. Reutilizado de `edit_user_profile_page.dart`.
class _BrazilianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < truncated.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (truncated.length == 11 && i == 7) buf.write('-');
      if (truncated.length == 10 && i == 6) buf.write('-');
      buf.write(truncated[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
