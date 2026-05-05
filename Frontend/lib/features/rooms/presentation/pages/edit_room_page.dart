import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/models/catalogo_item.dart';
import '../../domain/models/foto_existente.dart';
import '../notifiers/edit_room_notifier.dart';
import '../notifiers/edit_room_state.dart';
import '../notifiers/my_rooms_notifier.dart';

class EditRoomPage extends ConsumerStatefulWidget {
  final String roomId;

  const EditRoomPage({super.key, required this.roomId});

  @override
  ConsumerState<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends ConsumerState<EditRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  int _capacity = 2;
  bool _isActive = true;

  // Estado local de fotos e comodidades
  Set<int> _selectedComodidadeIds = {};
  final Set<String> _fotosParaRemover = {};
  List<XFile> _fotosNovas = [];

  bool _formPopulated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    Future.microtask(
        () => ref.read(editRoomNotifierProvider.notifier).load(widget.roomId));
  }

  void _tryPopulateForm(EditRoomState state) {
    if (_formPopulated) return;
    if (state.loading || state.loadError != null) return;
    if (state.nome == null) return;

    _formPopulated = true;
    _nameController.text = state.nome ?? '';
    _descriptionController.text = state.descricao ?? '';
    _priceController.text =
        state.valorDiaria?.toStringAsFixed(2) ?? '';
    setState(() {
      _capacity = state.capacidade ?? 2;
      _isActive = state.disponivel;
      _selectedComodidadeIds = Set.from(state.comodidadesAtuais);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage(
        maxHeight: 1000,
        maxWidth: 1000,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() => _fotosNovas = [..._fotosNovas, ...images]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagens: $e')),
        );
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final valorDiaria =
        double.tryParse(_priceController.text.trim().replaceAll(',', '.'));
    if (valorDiaria == null || valorDiaria <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Informe um valor de diária válido')),
      );
      return;
    }

    ref.read(editRoomNotifierProvider.notifier).save(
          nome: _nameController.text.trim(),
          descricao: _descriptionController.text.trim(),
          valorDiaria: valorDiaria,
          capacidade: _capacity,
          disponivel: _isActive,
          comodidadesSelecionadas: _selectedComodidadeIds,
          fotosParaRemover: _fotosParaRemover,
          fotosNovas: _fotosNovas,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editRoomNotifierProvider);

    ref.listen<EditRoomState>(editRoomNotifierProvider, (prev, next) {
      _tryPopulateForm(next);

      if (next.saveSuccess && !(prev?.saveSuccess ?? false)) {
        ref.read(myRoomsNotifierProvider.notifier).load();
        context.pop();
        return;
      }

      if (next.saveError != null && prev?.saveError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.saveError!),
            backgroundColor: Colors.red[700],
          ),
        );
        ref.read(editRoomNotifierProvider.notifier).clearSaveError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (state.saving) _buildProgressBar(state),
            Expanded(
              child: _buildBody(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(EditRoomState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                state.loadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.primary, fontSize: 15),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/my_rooms'),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildForm(state);
  }

  Widget _buildForm(EditRoomState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPhotosSection(state),
            const SizedBox(height: 24),
            _buildSectionLabel('Nome do Quarto'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'Ex: Quarto Luxo com Varanda',
              icon: Icons.meeting_room_outlined,
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Nome é obrigatório' : null,
            ),
            const SizedBox(height: 16),
            _buildSectionLabel('Descrição'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descriptionController,
              hint: 'Descreva o quarto',
              icon: Icons.description_outlined,
              maxLines: 3,
              validator: (v) =>
                  (v?.trim().isEmpty ?? true) ? 'Descrição é obrigatória' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Preço (R\$)'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _priceController,
                        hint: 'Ex: 249,90',
                        icon: Icons.attach_money_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[\d.,]')),
                        ],
                        validator: (v) {
                          final parsed = double.tryParse(
                              (v ?? '').trim().replaceAll(',', '.'));
                          if (parsed == null || parsed <= 0) {
                            return 'Valor inválido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Capacidade'),
                      const SizedBox(height: 8),
                      _buildStepper(
                        value: _capacity,
                        onChanged: (v) => setState(() => _capacity = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildAmenitiesSection(state),
            const SizedBox(height: 24),
            _buildStatusToggle(),
            const SizedBox(height: 32),
            PrimaryButton(
              text: state.saving ? 'Salvando...' : 'Salvar Alterações',
              isLoading: state.saving,
              onPressed: state.saving ? null : _submit,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: state.saving
                    ? null
                    : () => context.canPop()
                        ? context.pop()
                        : context.go('/my_rooms'),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Seção de fotos ─────────────────────────────────────────────────────────

  Widget _buildPhotosSection(EditRoomState state) {
    final fotosVisiveis = state.fotosExistentes
        .where((f) => !_fotosParaRemover.contains(f.id))
        .toList();
    final totalFotos = fotosVisiveis.length + _fotosNovas.length;

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fotos do Quarto ($totalFotos)',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined,
                    size: 18),
                label: const Text('Adicionar'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary),
              ),
            ],
          ),
          if (totalFotos == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Sem fotos. Toque em Adicionar para incluir.',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Fotos existentes (não marcadas para remoção)
                  ...fotosVisiveis.map((foto) => _buildExistingPhotoTile(foto)),
                  // Fotos novas (local)
                  ..._fotosNovas
                      .asMap()
                      .entries
                      .map((e) => _buildNewPhotoTile(e.key, e.value)),
                ],
              ),
            ),
          ],
          // Fotos marcadas para remoção (com indicador)
          if (_fotosParaRemover.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${_fotosParaRemover.length} foto(s) marcada(s) para remoção',
              style: TextStyle(
                  fontSize: 12, color: Colors.red[400]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExistingPhotoTile(FotoExistente foto) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              foto.url,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() => _fotosParaRemover.add(foto.id));
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPhotoTile(int index, XFile foto) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(foto.path,
                    width: 100, height: 100, fit: BoxFit.cover)
                : Image.file(File(foto.path),
                    width: 100, height: 100, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(
                    () => _fotosNovas.removeAt(index));
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 14),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Nova',
                style:
                    TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Seção de comodidades ───────────────────────────────────────────────────

  Widget _buildAmenitiesSection(EditRoomState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Comodidades'),
        const SizedBox(height: 8),
        if (state.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.secondary,
                ),
              ),
            ),
          )
        else if (state.catalogoItens.isEmpty)
          Text(
            'Sem comodidades no catálogo',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          )
        else
          _buildAmenitiesChips(state.catalogoItens),
      ],
    );
  }

  Widget _buildAmenitiesChips(List<CatalogoItemModel> itens) {
    final grupos = <String, List<CatalogoItemModel>>{};
    for (final item in itens) {
      grupos.putIfAbsent(item.categoria, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grupos.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF999999),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: entry.value.map((item) {
                  final selected =
                      _selectedComodidadeIds.contains(item.id);
                  return FilterChip(
                    label: Text(item.nome),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedComodidadeIds.add(item.id);
                        } else {
                          _selectedComodidadeIds.remove(item.id);
                        }
                      });
                    },
                    selectedColor: const Color(0xFF182541),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF444444),
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF182541)
                            : Colors.grey[300]!,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    showCheckmark: true,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Status toggle ──────────────────────────────────────────────────────────

  Widget _buildStatusToggle() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Status do Quarto',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Switch.adaptive(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeThumbColor: AppColors.secondary,
            activeTrackColor: AppColors.secondary.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  // ── Barra de progresso ─────────────────────────────────────────────────────

  Widget _buildProgressBar(EditRoomState state) {
    return Container(
      color: const Color(0xFFFFF3EE),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinearProgressIndicator(
            backgroundColor: Color(0xFFFFD5C2),
            valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFFEC6725)),
          ),
          if (state.saveStep != null) ...[
            const SizedBox(height: 6),
            Text(
              state.saveStep!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEC6725),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Widgets auxiliares ─────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF182541),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      padding:
          const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _headerIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => context.canPop()
                ? context.pop()
                : context.go('/my_rooms'),
          ),
          const Column(
            children: [
              Text(
                'RESERVAQUI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Editar Quarto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          _headerIconButton(
            icon: Icons.notifications_none,
            onTap: () => context.go('/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton(
      {required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      minLines: maxLines == 1 ? 1 : maxLines,
      validator: validator,
      style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.secondary),
        hintStyle:
            TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildStepper({
    required int value,
    required void Function(int) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 20),
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            color: AppColors.secondary,
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () => onChanged(value + 1),
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}
