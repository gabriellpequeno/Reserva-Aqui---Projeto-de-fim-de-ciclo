import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/catalogo_item.dart';
import '../../domain/models/foto_existente.dart';
import 'edit_room_state.dart';

class EditRoomNotifier extends Notifier<EditRoomState> {
  @override
  EditRoomState build() => const EditRoomState();

  Future<void> load(String roomId) async {
    // Limpa o state anterior completamente para não exibir dados velhos
    // caso o notifier seja reutilizado numa segunda abertura da tela.
    state = const EditRoomState(loading: true);

    try {
      final dio = ref.read(dioProvider);

      final hotelId = await _fetchHotelId(dio);
      if (hotelId == null) {
        state = state.copyWith(
          loading: false,
          loadError: 'Sessão expirada. Faça login novamente.',
        );
        return;
      }

      // Carrega quarto para obter categoriaQuartoId
      final quartoResponse =
          await dio.get<Map<String, dynamic>>('/hotel/quartos/$roomId');
      final quartoData =
          quartoResponse.data?['data'] as Map<String, dynamic>?;
      final categoriaId = quartoData?['categoria_quarto_id']?.toString();

      if (categoriaId == null) {
        state = state.copyWith(
          loading: false,
          loadError: 'Quarto não encontrado.',
        );
        return;
      }

      // Carrega categoria, fotos e catálogo em paralelo
      final results = await Future.wait([
        _loadCategoria(dio, hotelId, categoriaId),
        _loadFotos(dio, hotelId, roomId),
        _loadCatalogo(dio, hotelId),
      ], eagerError: false);

      final categoria = results[0] as Map<String, dynamic>?;
      final fotos = results[1] as List<FotoExistente>;
      final catalogo = results[2] as List<CatalogoItemModel>;

      // Extrai IDs das comodidades atuais da categoria
      final itensRaw = (categoria?['itens'] as List<dynamic>?) ?? [];
      final comodidadesAtuais = itensRaw
          .map((i) =>
              (i as Map<String, dynamic>)['catalogo_id'] as int? ?? 0)
          .where((id) => id != 0)
          .toSet();

      // Extrai valores para pré-popular o formulário
      // descricao e disponivel vêm do Quarto; os demais vêm da Categoria
      final nomeCat = categoria?['nome'] as String? ?? '';
      final valorDiaria = _parseDouble(categoria?['valor_diaria']);
      final capacidadeCat =
          categoria?['capacidade_pessoas'] as int? ?? 1;
      final descricaoQuarto = quartoData?['descricao'] as String?;
      final disponivelQuarto =
          quartoData?['disponivel'] as bool? ?? true;

      state = state.copyWith(
        loading: false,
        quartoId: roomId,
        categoriaId: categoriaId,
        hotelId: hotelId,
        nome: nomeCat,
        descricao: descricaoQuarto ?? '',
        valorDiaria: valorDiaria,
        capacidade: capacidadeCat,
        disponivel: disponivelQuarto,
        catalogoItens: catalogo,
        comodidadesAtuais: comodidadesAtuais,
        fotosExistentes: fotos,
      );
    } catch (e, st) {
      debugPrint('[editRoomNotifier] Erro ao carregar: $e\n$st');
      state = state.copyWith(
        loading: false,
        loadError: 'Não foi possível carregar os dados do quarto.',
      );
    }
  }

  Future<void> save({
    required String nome,
    required String descricao,
    required double valorDiaria,
    required int capacidade,
    required bool disponivel,
    required Set<int> comodidadesSelecionadas,
    required Set<String> fotosParaRemover,
    required List<XFile> fotosNovas,
  }) async {
    final quartoId = state.quartoId;
    final categoriaId = state.categoriaId;
    final hotelId = state.hotelId;

    if (quartoId == null || categoriaId == null || hotelId == null) return;

    state = state.copyWith(
      saving: true,
      saveStep: 'Atualizando categoria...',
      clearSaveError: true,
      saveSuccess: false,
    );

    try {
      final dio = ref.read(dioProvider);

      // 1. Atualizar categoria (sem descricao — campo pertence ao Quarto)
      await dio.patch<void>(
        '/hotel/categorias/$categoriaId',
        data: {
          'nome': nome,
          'valor_diaria': valorDiaria,
          'capacidade_pessoas': capacidade,
        },
      );

      // 2. Diff de comodidades
      final atuais = state.comodidadesAtuais;
      final adicionadas = comodidadesSelecionadas.difference(atuais);
      final removidas = atuais.difference(comodidadesSelecionadas);

      if (adicionadas.isNotEmpty || removidas.isNotEmpty) {
        state = state.copyWith(saveStep: 'Atualizando comodidades...');

        for (final id in adicionadas) {
          try {
            await dio.post<void>(
              '/hotel/categorias/$categoriaId/itens',
              data: {'catalogo_id': id, 'quantidade': 1},
            );
          } catch (e) {
            debugPrint('[editRoomNotifier] Falha ao adicionar item $id: $e');
          }
        }

        for (final id in removidas) {
          try {
            await dio.delete<void>(
                '/hotel/categorias/$categoriaId/itens/$id');
          } catch (e) {
            debugPrint('[editRoomNotifier] Falha ao remover item $id: $e');
          }
        }
      }

      // 3. Atualizar quarto físico (disponivel + descricao)
      state = state.copyWith(saveStep: 'Atualizando quarto...');
      await dio.patch<void>(
        '/hotel/quartos/$quartoId',
        data: {
          'disponivel': disponivel,
          if (descricao.isNotEmpty) 'descricao': descricao,
        },
      );

      // 4. Remover fotos marcadas
      if (fotosParaRemover.isNotEmpty) {
        state = state.copyWith(saveStep: 'Removendo fotos...');
        final apiBase = dio.options.baseUrl;
        for (final fotoId in fotosParaRemover) {
          try {
            await dio.delete<void>(
              '$apiBase/uploads/hotels/$hotelId/rooms/$quartoId/$fotoId',
            );
          } catch (e) {
            debugPrint(
                '[editRoomNotifier] Falha ao remover foto $fotoId: $e');
          }
        }
      }

      // 5. Upload de fotos novas
      if (fotosNovas.isNotEmpty) {
        state = state.copyWith(saveStep: 'Enviando fotos...');
        final apiBase = dio.options.baseUrl;
        for (final foto in fotosNovas) {
          try {
            final bytes = await foto.readAsBytes();
            final formData = FormData.fromMap({
              'foto': MultipartFile.fromBytes(bytes, filename: foto.name),
            });
            await dio.post<void>(
              '$apiBase/uploads/hotels/$hotelId/rooms/$quartoId',
              data: formData,
            );
          } catch (e) {
            debugPrint('[editRoomNotifier] Falha ao enviar foto: $e');
          }
        }
      }

      state = state.copyWith(
        saving: false,
        clearSaveStep: true,
        saveSuccess: true,
      );
    } catch (e, st) {
      debugPrint('[editRoomNotifier] Erro ao salvar: $e\n$st');
      state = state.copyWith(
        saving: false,
        clearSaveStep: true,
        saveError: _mensagemErro(e),
      );
    }
  }

  void clearSaveError() => state = state.copyWith(clearSaveError: true);

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String?> _fetchHotelId(Dio dio) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/hotel/me');
      final data = response.data?['data'] as Map<String, dynamic>?;
      final id = data?['hotel_id'] ?? data?['id'];
      return id?.toString();
    } catch (e) {
      debugPrint('[editRoomNotifier] Erro ao buscar hotel_id: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadCategoria(
      Dio dio, String hotelId, String categoriaId) async {
    try {
      final response = await dio
          .get<Map<String, dynamic>>('/hotel/$hotelId/categorias/$categoriaId');
      return response.data?['data'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('[editRoomNotifier] Erro ao carregar categoria: $e');
      return null;
    }
  }

  Future<List<FotoExistente>> _loadFotos(
      Dio dio, String hotelId, String quartoId) async {
    try {
      final apiBase = dio.options.baseUrl;
      final response = await dio.get<Map<String, dynamic>>(
        '$apiBase/uploads/hotels/$hotelId/rooms/$quartoId',
      );
      final fotos = (response.data?['fotos'] as List<dynamic>?) ?? [];
      return fotos
          .map((f) =>
              FotoExistente.fromJson(f as Map<String, dynamic>))
          .where((f) => f.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('[editRoomNotifier] Erro ao carregar fotos: $e');
      return [];
    }
  }

  Future<List<CatalogoItemModel>> _loadCatalogo(
      Dio dio, String hotelId) async {
    try {
      final response =
          await dio.get<Map<String, dynamic>>('/hotel/$hotelId/catalogo');
      final items = (response.data?['data'] as List<dynamic>?) ?? [];
      return items
          .map((i) =>
              CatalogoItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[editRoomNotifier] Erro ao carregar catálogo: $e');
      return [];
    }
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  String _mensagemErro(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 409) return 'Já existe uma categoria com este nome.';
      if (status == 400) return 'Dados inválidos. Verifique os campos.';
      if (status == 401 || status == 403) {
        return 'Sessão expirada. Faça login novamente.';
      }
      if (status == 404) return 'Quarto não encontrado.';
    }
    return 'Erro ao salvar. Tente novamente.';
  }
}

final editRoomNotifierProvider =
    NotifierProvider<EditRoomNotifier, EditRoomState>(EditRoomNotifier.new);
