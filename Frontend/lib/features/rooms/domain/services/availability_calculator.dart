import '../models/reserva_hotel.dart';

// Retorna o conjunto de dias indisponíveis para uma categoria com [totalUnidades] unidades.
// Um dia D é indisponível quando o número de reservas ativas que cobrem D é >= totalUnidades.
// Convenção: checkin inclusivo, checkout exclusivo (o dia do checkout ainda tem vaga).
//
// Conta dois tipos de reserva:
//   1. Reservas com quarto_id físico (ex: reservas via app)
//   2. Walk-ins BALCAO com tipo_quarto textual — sem quarto_id atribuído
Set<DateTime> computeDiasIndisponiveis(
  List<ReservaHotelModel> todasReservas,
  List<int> quartoIds,
  int totalUnidades, {
  String? nomeCategoria,
}) {
  if (totalUnidades <= 0 || quartoIds.isEmpty) return {};

  final nomeNorm = nomeCategoria?.toLowerCase().trim();

  final reservasDaCategoria = todasReservas.where((r) {
    if (!r.ativa) return false;
    // Reserva com quarto físico pertencente a esta categoria
    if (r.quartoId != null && quartoIds.contains(r.quartoId)) return true;
    // Walk-in BALCAO sem quarto atribuído — identifica pela categoria textual
    if (r.quartoId == null && nomeNorm != null && r.tipoQuarto != null) {
      return r.tipoQuarto!.toLowerCase().trim() == nomeNorm;
    }
    return false;
  }).toList();

  if (reservasDaCategoria.isEmpty) return {};

  // Janela de datas a avaliar: do checkin mais cedo ao checkout mais tarde
  final minDate = reservasDaCategoria
      .map((r) => r.dataCheckin)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  final maxDate = reservasDaCategoria
      .map((r) => r.dataCheckout)
      .reduce((a, b) => a.isAfter(b) ? a : b);

  final indisponiveis = <DateTime>{};
  var dia = DateTime(minDate.year, minDate.month, minDate.day);
  final fim = DateTime(maxDate.year, maxDate.month, maxDate.day);

  while (!dia.isAfter(fim)) {
    final ocupacao = reservasDaCategoria.where((r) {
      final checkin  = DateTime(r.dataCheckin.year, r.dataCheckin.month, r.dataCheckin.day);
      final checkout = DateTime(r.dataCheckout.year, r.dataCheckout.month, r.dataCheckout.day);
      return !dia.isBefore(checkin) && dia.isBefore(checkout);
    }).length;

    if (ocupacao >= totalUnidades) {
      indisponiveis.add(dia);
    }

    dia = dia.add(const Duration(days: 1));
  }

  return indisponiveis;
}
