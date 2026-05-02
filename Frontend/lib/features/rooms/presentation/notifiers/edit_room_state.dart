import '../../domain/models/catalogo_item.dart';
import '../../domain/models/foto_existente.dart';

class EditRoomState {
  final bool loading;
  final String? loadError;

  final String? quartoId;
  final String? categoriaId;
  final String? hotelId;

  // Valores carregados da API — usados para popular o formulário
  final String? nome;
  final String? descricao;
  final double? valorDiaria;
  final int? capacidade;
  final bool disponivel;

  final List<CatalogoItemModel> catalogoItens;
  final Set<int> comodidadesAtuais;
  final List<FotoExistente> fotosExistentes;

  final bool saving;
  final String? saveStep;
  final String? saveError;
  final bool saveSuccess;

  const EditRoomState({
    this.loading = false,
    this.loadError,
    this.quartoId,
    this.categoriaId,
    this.hotelId,
    this.nome,
    this.descricao,
    this.valorDiaria,
    this.capacidade,
    this.disponivel = true,
    this.catalogoItens = const [],
    this.comodidadesAtuais = const {},
    this.fotosExistentes = const [],
    this.saving = false,
    this.saveStep,
    this.saveError,
    this.saveSuccess = false,
  });

  EditRoomState copyWith({
    bool? loading,
    String? loadError,
    bool clearLoadError = false,
    String? quartoId,
    String? categoriaId,
    String? hotelId,
    String? nome,
    String? descricao,
    double? valorDiaria,
    int? capacidade,
    bool? disponivel,
    List<CatalogoItemModel>? catalogoItens,
    Set<int>? comodidadesAtuais,
    List<FotoExistente>? fotosExistentes,
    bool? saving,
    String? saveStep,
    bool clearSaveStep = false,
    String? saveError,
    bool clearSaveError = false,
    bool? saveSuccess,
  }) {
    return EditRoomState(
      loading: loading ?? this.loading,
      loadError: clearLoadError ? null : (loadError ?? this.loadError),
      quartoId: quartoId ?? this.quartoId,
      categoriaId: categoriaId ?? this.categoriaId,
      hotelId: hotelId ?? this.hotelId,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      valorDiaria: valorDiaria ?? this.valorDiaria,
      capacidade: capacidade ?? this.capacidade,
      disponivel: disponivel ?? this.disponivel,
      catalogoItens: catalogoItens ?? this.catalogoItens,
      comodidadesAtuais: comodidadesAtuais ?? this.comodidadesAtuais,
      fotosExistentes: fotosExistentes ?? this.fotosExistentes,
      saving: saving ?? this.saving,
      saveStep: clearSaveStep ? null : (saveStep ?? this.saveStep),
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
      saveSuccess: saveSuccess ?? this.saveSuccess,
    );
  }
}
