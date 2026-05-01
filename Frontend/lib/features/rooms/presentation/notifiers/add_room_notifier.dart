import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/catalogo_item.dart';
import 'add_room_state.dart';

class AddRoomNotifier extends Notifier<AddRoomState> {
  @override
  AddRoomState build() => const AddRoomState();

  Future<void> loadCatalogo() async {
    state = state.copyWith(loadingCatalogo: true, clearError: true);

    try {
      final dio = ref.read(dioProvider);
      final hotelId = await _fetchHotelId(dio);

      if (hotelId == null) {
        state = state.copyWith(
          loadingCatalogo: false,
          error: 'Sessão expirada. Faça login novamente.',
        );
        return;
      }

      final response =
          await dio.get<Map<String, dynamic>>('/hotel/$hotelId/catalogo');
      final items = (response.data?['data'] as List<dynamic>?) ?? [];
      state = state.copyWith(
        catalogoItens: items
            .map((i) => CatalogoItemModel.fromJson(i as Map<String, dynamic>))
            .toList(),
        loadingCatalogo: false,
      );
    } catch (e, st) {
      debugPrint('[addRoomNotifier] Erro ao carregar catálogo: $e\n$st');
      state = state.copyWith(
        loadingCatalogo: false,
        error: 'Não foi possível carregar as comodidades.',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> submit({
    required String nome,
    required double valorDiaria,
    required int capacidade,
    required Set<int> comodidadeIds,
    required int numeroUnidades,
    required List<XFile> fotos,
  }) async {
    state = state.copyWith(
      submitting: true,
      submitStep: 'Criando categoria...',
      clearError: true,
      success: false,
    );

    try {
      final dio = ref.read(dioProvider);
      final hotelId = await _fetchHotelId(dio);

      if (hotelId == null) {
        state = state.copyWith(
          submitting: false,
          clearStep: true,
          error: 'Sessão expirada. Faça login novamente.',
        );
        return;
      }

      // 1. Criar categoria
      final catResponse = await dio.post<Map<String, dynamic>>(
        '/hotel/categorias',
        data: {
          'nome': nome,
          'valor_diaria': valorDiaria,
          'capacidade_pessoas': capacidade,
        },
      );
      final categoriaId =
          (catResponse.data?['data'] as Map<String, dynamic>?)?['id'] as int?;

      if (categoriaId == null) throw Exception('categoria_id não retornado');

      // 2. Adicionar comodidades
      if (comodidadeIds.isNotEmpty) {
        state = state.copyWith(submitStep: 'Adicionando comodidades...');
        for (final id in comodidadeIds) {
          try {
            await dio.post<void>(
              '/hotel/categorias/$categoriaId/itens',
              data: {'catalogo_id': id, 'quantidade': 1},
            );
          } catch (e) {
            debugPrint('[addRoomNotifier] Falha ao adicionar item $id: $e');
          }
        }
      }

      // 3. Criar unidades físicas
      state = state.copyWith(submitStep: 'Criando quartos...');
      int? primeiroQuartoId;
      final quartosCriados = <int>[];

      // Usa categoriaId como prefixo para evitar colisão com soft-deleted rows de outras categorias
      for (var i = 0; i < numeroUnidades; i++) {
        final numero = '${categoriaId}_${i + 1}';
        try {
          final quartoResponse = await dio.post<Map<String, dynamic>>(
            '/hotel/quartos',
            data: {
              'numero': numero,
              'categoria_quarto_id': categoriaId,
            },
          );
          final quartoId =
              (quartoResponse.data?['data'] as Map<String, dynamic>?)?['id']
                  as int?;
          if (quartoId != null) {
            quartosCriados.add(quartoId);
            primeiroQuartoId ??= quartoId;
          }
        } catch (e) {
          debugPrint('[addRoomNotifier] Falha ao criar quarto $numero: $e');
          // Rollback: remove quartos já criados e a categoria
          await _rollbackCategoria(dio, categoriaId, quartosCriados);
          rethrow;
        }
      }

      // 4. Upload de fotos para todos os quartos criados
      // Assim a foto sobrevive mesmo que alguns quartos sejam excluídos depois
      if (fotos.isNotEmpty && quartosCriados.isNotEmpty) {
        state = state.copyWith(submitStep: 'Enviando fotos...');
        final uploadBase = dio.options.baseUrl;

        for (final quartoId in quartosCriados) {
          for (final foto in fotos) {
            try {
              final bytes = await foto.readAsBytes();
              final formData = FormData.fromMap({
                'foto': MultipartFile.fromBytes(bytes, filename: foto.name),
              });
              await dio.post<void>(
                '$uploadBase/uploads/hotels/$hotelId/rooms/$quartoId',
                data: formData,
              );
            } catch (e) {
              debugPrint('[addRoomNotifier] Falha ao enviar foto para quarto $quartoId: $e');
            }
          }
        }
      }

      state = state.copyWith(
        submitting: false,
        clearStep: true,
        success: true,
      );
    } catch (e, st) {
      debugPrint('[addRoomNotifier] Erro no submit: $e\n$st');
      state = state.copyWith(
        submitting: false,
        clearStep: true,
        error: _mensagemErro(e),
      );
    }
  }

  Future<void> _rollbackCategoria(
    Dio dio,
    int categoriaId,
    List<int> quartoIds,
  ) async {
    for (final id in quartoIds) {
      try {
        await dio.delete<void>('/hotel/quartos/$id');
      } catch (e) {
        debugPrint('[addRoomNotifier] Rollback: falha ao deletar quarto $id: $e');
      }
    }
    try {
      await dio.delete<void>('/hotel/categorias/$categoriaId');
    } catch (e) {
      debugPrint('[addRoomNotifier] Rollback: falha ao deletar categoria $categoriaId: $e');
    }
  }

  Future<String?> _fetchHotelId(Dio dio) async {
    try {
      final response = await dio.get<Map<String, dynamic>>('/hotel/me');
      final data = response.data?['data'] as Map<String, dynamic>?;
      final id = data?['hotel_id'] ?? data?['id'];
      return id?.toString();
    } catch (e) {
      debugPrint('[addRoomNotifier] Erro ao buscar hotel_id: $e');
      return null;
    }
  }

  String _mensagemErro(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 409) return 'Já existe uma categoria com este nome.';
      if (status == 400) return 'Dados inválidos. Verifique os campos.';
      if (status == 401 || status == 403) {
        return 'Sessão expirada. Faça login novamente.';
      }
    }
    return 'Erro ao criar quarto. Tente novamente.';
  }
}

final addRoomNotifierProvider =
    NotifierProvider<AddRoomNotifier, AddRoomState>(AddRoomNotifier.new);
