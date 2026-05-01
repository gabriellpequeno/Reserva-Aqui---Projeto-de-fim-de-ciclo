import '../../domain/models/catalogo_item.dart';

class AddRoomState {
  final List<CatalogoItemModel> catalogoItens;
  final bool loadingCatalogo;
  final bool submitting;
  final String? submitStep;
  final String? error;
  final bool success;

  const AddRoomState({
    this.catalogoItens = const [],
    this.loadingCatalogo = false,
    this.submitting = false,
    this.submitStep,
    this.error,
    this.success = false,
  });

  AddRoomState copyWith({
    List<CatalogoItemModel>? catalogoItens,
    bool? loadingCatalogo,
    bool? submitting,
    String? submitStep,
    String? error,
    bool? success,
    bool clearError = false,
    bool clearStep = false,
  }) {
    return AddRoomState(
      catalogoItens: catalogoItens ?? this.catalogoItens,
      loadingCatalogo: loadingCatalogo ?? this.loadingCatalogo,
      submitting: submitting ?? this.submitting,
      submitStep: clearStep ? null : (submitStep ?? this.submitStep),
      error: clearError ? null : (error ?? this.error),
      success: success ?? this.success,
    );
  }
}
