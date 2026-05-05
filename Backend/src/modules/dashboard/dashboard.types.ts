// Types do módulo dashboard — contratos públicos dos endpoints
// GET /host/dashboard e GET /admin/dashboard.

export type Period = 'today' | 'last7' | 'current_month' | 'last30';

export const ALL_PERIODS: readonly Period[] = [
  'today',
  'last7',
  'current_month',
  'last30',
] as const;

export type ReservaStatus =
  | 'SOLICITADA'
  | 'AGUARDANDO_PAGAMENTO'
  | 'APROVADA'
  | 'CANCELADA'
  | 'CONCLUIDA';

export interface ReservaStatusCount {
  status: ReservaStatus;
  count:  number;
}

export interface NextCheckin {
  reservaId:     number;
  codigoPublico: string;
  nomeHospede:   string;
  quartoNumero:  string | null;
  tipoQuarto:    string | null;
  dataCheckin:   string; // ISO-8601 date (YYYY-MM-DD)
}

export interface TopHotel {
  hotelId:        string;
  nomeHotel:      string;
  reservasAtivas: number;
}

export interface HostDashboardMetrics {
  reservasHoje:       number;
  ocupacaoPercentual: number;       // 0-100; 0 se total de quartos = 0
  receitaPeriodo:     number;
  avaliacaoMedia:     number | null; // null se totalAvaliacoes = 0
  totalAvaliacoes:    number;
  taxaCancelamento:   number;       // 0-100; 0 se não há reservas no período
  estadiaMediaDias:   number | null; // null se não há reservas concluídas no período
}

export interface HostDashboardResponse {
  period:            Period;
  metrics:           HostDashboardMetrics;
  proximosCheckins:  NextCheckin[];       // limit 5
  reservasPorStatus: ReservaStatusCount[];
}

export interface AdminDashboardMetrics {
  totalUsuarios:     number;
  totalHoteis:       number;
  reservasHoje:      number;
  receitaPeriodo:    number;
  receitaMediaHotel: number; // receitaPeriodo / totalHoteis (0 se sem hotéis)
}

export interface MelhorAvaliado {
  hotelId:        string;
  nomeHotel:      string;
  avaliacaoMedia: number;   // 1-5
  totalAvaliacoes: number;
}

export interface NovosCadastros {
  usuarios: number; // últimos 7 dias (fixo)
  hoteis:   number; // últimos 7 dias (fixo)
}

export interface AdminDashboardResponse {
  period:            Period;
  metrics:           AdminDashboardMetrics;
  topHoteis:         TopHotel[];          // limit 3, desc por reservasAtivas
  reservasPorStatus: ReservaStatusCount[];
  novosCadastros:    NovosCadastros;
  melhorAvaliado:    MelhorAvaliado | null; // null se nenhum hotel tem avaliação
}
