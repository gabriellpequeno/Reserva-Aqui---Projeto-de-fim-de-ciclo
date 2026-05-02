import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/catalogo_item.dart';
import '../notifiers/add_room_notifier.dart';
import '../notifiers/add_room_state.dart';
import '../notifiers/my_rooms_notifier.dart';

class AddRoomPage extends ConsumerStatefulWidget {
  const AddRoomPage({super.key});

  @override
  ConsumerState<AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends ConsumerState<AddRoomPage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  int _capacity = 2;
  int _numberOfRooms = 1;
  List<XFile> _selectedImages = [];
  final Set<int> _selectedAmenityIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(addRoomNotifierProvider.notifier).loadCatalogo());
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxHeight: 1000,
        maxWidth: 1000,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() => _selectedImages = [..._selectedImages, ...images]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagens: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma imagem')),
      );
      return;
    }

    final valorDiaria = double.tryParse(
        _priceController.text.trim().replaceAll(',', '.'));
    if (valorDiaria == null || valorDiaria <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor de diária válido')),
      );
      return;
    }

    ref.read(addRoomNotifierProvider.notifier).submit(
          nome: _roomNameController.text.trim(),
          valorDiaria: valorDiaria,
          capacidade: _capacity,
          comodidadeIds: _selectedAmenityIds,
          numeroUnidades: _numberOfRooms,
          fotos: _selectedImages,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addRoomNotifierProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Listener de resultado
    ref.listen<AddRoomState>(addRoomNotifierProvider, (prev, next) {
      if (next.success && !(prev?.success ?? false)) {
        ref.read(myRoomsNotifierProvider.notifier).load();
        context.pop();
        return;
      }
      if (next.error != null && prev?.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red[700],
          ),
        );
        ref.read(addRoomNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildCustomAppBar(),
                if (state.submitting) _buildProgressBar(state),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16.0 : 32.0,
                    vertical: 24.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 20,
                      children: [
                        _buildTextField(
                          controller: _roomNameController,
                          label: 'Nome Do Quarto',
                          hint: 'Ex: Quarto Luxo com Varanda',
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Nome do quarto é obrigatório';
                            }
                            return null;
                          },
                        ),
                        _buildTwoColumnRow(
                          first: _buildNumberInput(
                            label: 'Capacidade',
                            value: _capacity,
                            onChanged: (v) => setState(() => _capacity = v),
                          ),
                          second: _buildNumberInput(
                            label: 'Nº Quartos',
                            value: _numberOfRooms,
                            onChanged: (v) =>
                                setState(() => _numberOfRooms = v),
                          ),
                        ),
                        _buildPriceField(),
                        _buildAmenitiesSection(state),
                        _buildDescriptionField(),
                        const SizedBox(height: 8),
                        _buildImageSection(),
                        const SizedBox(height: 20),
                        _buildSubmitButton(state),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(AddRoomState state) {
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
          if (state.submitStep != null) ...[
            const SizedBox(height: 6),
            Text(
              state.submitStep!,
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

  Widget _buildCustomAppBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF182541),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(27),
          bottomRight: Radius.circular(27),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 24),
            ),
          ),
          Column(
            children: const [
              Text(
                'RESERVAQUI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Novo Quarto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.go('/notifications'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications,
                  color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: _inputDecoration(hint),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valor da Diária (R\$)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _priceController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: _inputDecoration('Ex: 249,90'),
          validator: (value) {
            final v = double.tryParse(
                (value ?? '').trim().replaceAll(',', '.'));
            if (v == null || v <= 0) {
              return 'Informe um valor válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection(AddRoomState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comodidades',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (state.loadingCatalogo)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFEC6725),
                ),
              ),
            ),
          )
        else if (state.catalogoItens.isEmpty)
          Text(
            'Sem comodidades cadastradas',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          )
        else
          _buildAmenitiesChips(state.catalogoItens),
      ],
    );
  }

  Widget _buildAmenitiesChips(List<CatalogoItemModel> itens) {
    // Agrupar por categoria
    final grupos = <String, List<CatalogoItemModel>>{};
    for (final item in itens) {
      grupos.putIfAbsent(item.categoria, () => []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: grupos.entries.map((entry) {
        return Column(
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
                final selected = _selectedAmenityIds.contains(item.id);
                return FilterChip(
                  label: Text(item.nome),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedAmenityIds.add(item.id);
                      } else {
                        _selectedAmenityIds.remove(item.id);
                      }
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  showCheckmark: true,
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrição',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 100,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: _inputDecoration('Texto com até 100 caracteres'),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Descrição é obrigatória';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required int value,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20),
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
              ),
              Text(
                value.toString(),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTwoColumnRow({
    required Widget first,
    required Widget second,
  }) {
    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 16),
        Expanded(child: second),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Adicionar Fotos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF182541),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            Text(
              'Recomendado pelo\nmenos 5 imagens',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Fotos Selecionadas (${_selectedImages.length})',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(
                                _selectedImages[index].path,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_selectedImages[index].path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF2828),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(AddRoomState state) {
    return ElevatedButton(
      onPressed: state.submitting ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEC6725),
        disabledBackgroundColor: const Color(0xFFEC6725).withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: state.submitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Criar quarto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      filled: true,
      fillColor: colorScheme.surfaceContainer,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }
}
