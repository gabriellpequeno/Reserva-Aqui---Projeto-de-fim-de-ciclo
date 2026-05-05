import 'dashboard_period.dart';
import 'next_checkin_model.dart';
import 'reserva_status_count.dart';

class HostDashboardMetrics {
  final int reservasHoje;
  final double ocupacaoPercentual;
  final double receitaPeriodo;
  final double? avaliacaoMedia;
  final int totalAvaliacoes;
  final double taxaCancelamento;
  final double? estadiaMediaDias;

  const HostDashboardMetrics({
    required this.reservasHoje,
    required this.ocupacaoPercentual,
    required this.receitaPeriodo,
    required this.avaliacaoMedia,
    required this.totalAvaliacoes,
    required this.taxaCancelamento,
    required this.estadiaMediaDias,
  });

  factory HostDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return HostDashboardMetrics(
      reservasHoje: (json['reservasHoje'] as num?)?.toInt() ?? 0,
      ocupacaoPercentual: _toDouble(json['ocupacaoPercentual']),
      receitaPeriodo: _toDouble(json['receitaPeriodo']),
      avaliacaoMedia: json['avaliacaoMedia'] == null
          ? null
          : _toDouble(json['avaliacaoMedia']),
      totalAvaliacoes: (json['totalAvaliacoes'] as num?)?.toInt() ?? 0,
      taxaCancelamento: _toDouble(json['taxaCancelamento']),
      estadiaMediaDias: json['estadiaMediaDias'] == null
          ? null
          : _toDouble(json['estadiaMediaDias']),
    );
  }
}

class HostDashboardState {
  final DashboardPeriod period;
  final HostDashboardMetrics metrics;
  final List<NextCheckinModel> proximosCheckins;
  final List<ReservaStatusCount> reservasPorStatus;

  const HostDashboardState({
    required this.period,
    required this.metrics,
    required this.proximosCheckins,
    required this.reservasPorStatus,
  });

  factory HostDashboardState.fromJson(Map<String, dynamic> json) {
    return HostDashboardState(
      period: DashboardPeriod.fromString(json['period'] as String?),
      metrics: HostDashboardMetrics.fromJson(
        (json['metrics'] as Map).cast<String, dynamic>(),
      ),
      proximosCheckins: ((json['proximosCheckins'] as List?) ?? const [])
          .map((e) => NextCheckinModel.fromJson((e as Map).cast<String, dynamic>()))
          .whereType<NextCheckinModel>()
          .toList(),
      reservasPorStatus: ((json['reservasPorStatus'] as List?) ?? const [])
          .map((e) => ReservaStatusCount.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  HostDashboardState copyWith({
    DashboardPeriod? period,
    HostDashboardMetrics? metrics,
    List<NextCheckinModel>? proximosCheckins,
    List<ReservaStatusCount>? reservasPorStatus,
  }) {
    return HostDashboardState(
      period: period ?? this.period,
      metrics: metrics ?? this.metrics,
      proximosCheckins: proximosCheckins ?? this.proximosCheckins,
      reservasPorStatus: reservasPorStatus ?? this.reservasPorStatus,
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}
