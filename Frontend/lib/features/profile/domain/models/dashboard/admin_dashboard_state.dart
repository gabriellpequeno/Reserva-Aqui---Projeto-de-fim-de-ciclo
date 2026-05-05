import 'dashboard_period.dart';
import 'reserva_status_count.dart';
import 'top_hotel_model.dart';

class AdminDashboardMetrics {
  final int totalUsuarios;
  final int totalHoteis;
  final int reservasHoje;
  final double receitaPeriodo;
  final double receitaMediaHotel;

  const AdminDashboardMetrics({
    required this.totalUsuarios,
    required this.totalHoteis,
    required this.reservasHoje,
    required this.receitaPeriodo,
    required this.receitaMediaHotel,
  });

  factory AdminDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return AdminDashboardMetrics(
      totalUsuarios: (json['totalUsuarios'] as num?)?.toInt() ?? 0,
      totalHoteis: (json['totalHoteis'] as num?)?.toInt() ?? 0,
      reservasHoje: (json['reservasHoje'] as num?)?.toInt() ?? 0,
      receitaPeriodo: _toDouble(json['receitaPeriodo']),
      receitaMediaHotel: _toDouble(json['receitaMediaHotel']),
    );
  }
}

class MelhorAvaliadoModel {
  final String hotelId;
  final String nomeHotel;
  final double avaliacaoMedia;
  final int totalAvaliacoes;

  const MelhorAvaliadoModel({
    required this.hotelId,
    required this.nomeHotel,
    required this.avaliacaoMedia,
    required this.totalAvaliacoes,
  });

  factory MelhorAvaliadoModel.fromJson(Map<String, dynamic> json) {
    return MelhorAvaliadoModel(
      hotelId: (json['hotelId'] as String?) ?? '',
      nomeHotel: (json['nomeHotel'] as String?) ?? '',
      avaliacaoMedia: _toDouble(json['avaliacaoMedia']),
      totalAvaliacoes: (json['totalAvaliacoes'] as num?)?.toInt() ?? 0,
    );
  }
}

class NovosCadastros {
  final int usuarios;
  final int hoteis;

  const NovosCadastros({
    required this.usuarios,
    required this.hoteis,
  });

  factory NovosCadastros.fromJson(Map<String, dynamic> json) {
    return NovosCadastros(
      usuarios: (json['usuarios'] as num?)?.toInt() ?? 0,
      hoteis: (json['hoteis'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminDashboardState {
  final DashboardPeriod period;
  final AdminDashboardMetrics metrics;
  final List<TopHotelModel> topHoteis;
  final List<ReservaStatusCount> reservasPorStatus;
  final NovosCadastros novosCadastros;
  final MelhorAvaliadoModel? melhorAvaliado;

  const AdminDashboardState({
    required this.period,
    required this.metrics,
    required this.topHoteis,
    required this.reservasPorStatus,
    required this.novosCadastros,
    required this.melhorAvaliado,
  });

  factory AdminDashboardState.fromJson(Map<String, dynamic> json) {
    return AdminDashboardState(
      period: DashboardPeriod.fromString(json['period'] as String?),
      metrics: AdminDashboardMetrics.fromJson(
        (json['metrics'] as Map).cast<String, dynamic>(),
      ),
      topHoteis: ((json['topHoteis'] as List?) ?? const [])
          .map((e) => TopHotelModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      reservasPorStatus: ((json['reservasPorStatus'] as List?) ?? const [])
          .map((e) => ReservaStatusCount.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      novosCadastros: NovosCadastros.fromJson(
        (json['novosCadastros'] as Map).cast<String, dynamic>(),
      ),
      melhorAvaliado: json['melhorAvaliado'] == null
          ? null
          : MelhorAvaliadoModel.fromJson(
              (json['melhorAvaliado'] as Map).cast<String, dynamic>()),
    );
  }

  AdminDashboardState copyWith({
    DashboardPeriod? period,
    AdminDashboardMetrics? metrics,
    List<TopHotelModel>? topHoteis,
    List<ReservaStatusCount>? reservasPorStatus,
    NovosCadastros? novosCadastros,
    MelhorAvaliadoModel? melhorAvaliado,
  }) {
    return AdminDashboardState(
      period: period ?? this.period,
      metrics: metrics ?? this.metrics,
      topHoteis: topHoteis ?? this.topHoteis,
      reservasPorStatus: reservasPorStatus ?? this.reservasPorStatus,
      novosCadastros: novosCadastros ?? this.novosCadastros,
      melhorAvaliado: melhorAvaliado ?? this.melhorAvaliado,
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}
