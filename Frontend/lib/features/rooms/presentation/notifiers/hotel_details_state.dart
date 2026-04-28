import '../../domain/models/hotel_details.dart';

class HotelDetailsState {
  final String? nome;
  final String? descricao;
  final String? cidade;
  final String? uf;
  final List<String> coverUrls;
  final List<ComodidadeHotelModel> comodidades;
  final List<CategoriaHotelModel> categorias;
  final List<AvaliacaoHotelModel> avaliacoes;
  final double notaMedia;
  final PoliticasHotelModel? politicas;
  final bool isLoading;
  final bool hasError;

  const HotelDetailsState({
    this.nome,
    this.descricao,
    this.cidade,
    this.uf,
    this.coverUrls = const [],
    this.comodidades = const [],
    this.categorias = const [],
    this.avaliacoes = const [],
    this.notaMedia = 0.0,
    this.politicas,
    this.isLoading = false,
    this.hasError = false,
  });

  HotelDetailsState copyWith({
    String? nome,
    String? descricao,
    String? cidade,
    String? uf,
    List<String>? coverUrls,
    List<ComodidadeHotelModel>? comodidades,
    List<CategoriaHotelModel>? categorias,
    List<AvaliacaoHotelModel>? avaliacoes,
    double? notaMedia,
    PoliticasHotelModel? politicas,
    bool? isLoading,
    bool? hasError,
  }) {
    return HotelDetailsState(
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      cidade: cidade ?? this.cidade,
      uf: uf ?? this.uf,
      coverUrls: coverUrls ?? this.coverUrls,
      comodidades: comodidades ?? this.comodidades,
      categorias: categorias ?? this.categorias,
      avaliacoes: avaliacoes ?? this.avaliacoes,
      notaMedia: notaMedia ?? this.notaMedia,
      politicas: politicas ?? this.politicas,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}
