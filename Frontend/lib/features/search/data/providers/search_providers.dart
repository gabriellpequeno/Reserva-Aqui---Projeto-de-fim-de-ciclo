import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/network/dio_client.dart';
import '../services/search_service.dart';
import '../services/avaliacao_service.dart';
import '../services/upload_service.dart';

final searchServiceProvider = Provider<SearchService>((ref) {
  final dio = ref.watch(dioProvider);
  return SearchService(dio: dio);
});

final avaliacaoServiceProvider = Provider<AvaliacaoService>((ref) {
  final dio = ref.watch(dioProvider);
  return AvaliacaoService(dio: dio);
});

final uploadServiceProvider = Provider<UploadService>((ref) {
  final dio = ref.watch(dioProvider);
  return UploadService(dio: dio);
});
