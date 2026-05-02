/// Presets de período aceitos pelos endpoints `/host/dashboard` e
/// `/admin/dashboard`. Mapeamento 1:1 com o enum `Period` do backend.
enum DashboardPeriod {
  today,
  last7,
  currentMonth,
  last30;

  /// Valor aceito pelo backend no query param `?period=`.
  String toQueryValue() {
    switch (this) {
      case DashboardPeriod.today:
        return 'today';
      case DashboardPeriod.last7:
        return 'last7';
      case DashboardPeriod.currentMonth:
        return 'current_month';
      case DashboardPeriod.last30:
        return 'last30';
    }
  }

  /// Label apresentado no seletor de período da UI.
  String toLabel() {
    switch (this) {
      case DashboardPeriod.today:
        return 'Hoje';
      case DashboardPeriod.last7:
        return 'Últimos 7 dias';
      case DashboardPeriod.currentMonth:
        return 'Mês corrente';
      case DashboardPeriod.last30:
        return 'Últimos 30 dias';
    }
  }

  /// Reconstrói a enum a partir do valor do backend (fallback tolerante em `today`).
  static DashboardPeriod fromString(String? value) {
    switch (value) {
      case 'today':
        return DashboardPeriod.today;
      case 'last7':
        return DashboardPeriod.last7;
      case 'current_month':
        return DashboardPeriod.currentMonth;
      case 'last30':
        return DashboardPeriod.last30;
      default:
        return DashboardPeriod.today;
    }
  }
}
