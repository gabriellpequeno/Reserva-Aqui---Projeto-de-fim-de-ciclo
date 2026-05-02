import 'reserva_status.dart';

class ReservaStatusCount {
  final ReservaStatus status;
  final int count;

  const ReservaStatusCount({
    required this.status,
    required this.count,
  });

  factory ReservaStatusCount.fromJson(Map<String, dynamic> json) {
    return ReservaStatusCount(
      status: ReservaStatus.fromString(json['status'] as String?),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
