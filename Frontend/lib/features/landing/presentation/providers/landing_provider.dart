import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../rooms/domain/models/room.dart';
import '../../data/services/landing_service.dart';

final featuredRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final service = ref.read(landingServiceProvider);
  return service.getFeaturedRooms();
});
