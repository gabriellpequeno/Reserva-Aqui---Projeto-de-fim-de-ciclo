import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';

class AvailabilityChecker extends StatefulWidget {
  final String hotelId;
  final int categoriaId;

  const AvailabilityChecker({
    super.key,
    required this.hotelId,
    required this.categoriaId,
  });

  @override
  State<AvailabilityChecker> createState() => _AvailabilityCheckerState();
}

class _AvailabilityCheckerState extends State<AvailabilityChecker> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  bool _isLoading = false;
  String? _resultMessage;
  bool _isAvailable = false;

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  // Botão de verificação: chama GET /:hotel_id/disponibilidade e filtra pelo categoriaId do quarto
  Future<void> _checkAvailability() async {
    if (_checkInDate == null || _checkOutDate == null) return;

    setState(() => _isLoading = true);

    try {
      final dio = Dio(BaseOptions(
        baseUrl: 'http://10.0.2.2:3000/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final response = await dio.get<Map<String, dynamic>>(
        '/hotel/${widget.hotelId}/disponibilidade',
        queryParameters: {
          'data_checkin': _checkInDate!.toString().split(' ')[0],
          'data_checkout': _checkOutDate!.toString().split(' ')[0],
        },
      );

      final disponibilidades =
          (response.data!['data'] as List<dynamic>? ?? []);

      // Filtragem: busca a entrada da categoria do quarto atual no array de disponibilidade retornado
      final categoriaDisp = disponibilidades.firstWhere(
        (item) => (item as Map<String, dynamic>)['id'] == widget.categoriaId,
        orElse: () => null,
      ) as Map<String, dynamic>?;

      if (categoriaDisp == null) {
        setState(() {
          _resultMessage = 'Categoria não encontrada';
          _isAvailable = false;
          _isLoading = false;
        });
        return;
      }

      // Exibição do resultado: mensagem de disponível ou indisponível abaixo do botão
      final disponivel = categoriaDisp['disponivel'] as bool? ?? false;
      final proximaData = categoriaDisp['proxima_disponibilidade'] as String?;

      setState(() {
        _isAvailable = disponivel;
        _resultMessage = disponivel
            ? 'Disponível'
            : 'Indisponível — próxima disponibilidade em ${proximaData ?? 'data desconhecida'}';
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _resultMessage = 'Erro ao verificar disponibilidade';
        _isAvailable = false;
        _isLoading = false;
      });
      debugPrint('[availabilityChecker] Erro: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'Verificar Disponibilidade',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Check-in',
                              style: TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _checkInDate != null
                                  ? '${_checkInDate!.day}/${_checkInDate!.month}/${_checkInDate!.year}'
                                  : 'Selecionar',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _selectDate(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Check-out',
                              style: TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _checkOutDate != null
                                  ? '${_checkOutDate!.day}/${_checkOutDate!.month}/${_checkOutDate!.year}'
                                  : 'Selecionar',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_checkInDate == null ||
                    _checkOutDate == null ||
                    _isLoading)
                ? null
                : _checkAvailability,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              disabledBackgroundColor: Colors.grey[400],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 36),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Verificar disponibilidade',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        if (_resultMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isAvailable
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _resultMessage!,
              style: TextStyle(
                color: _isAvailable ? Colors.green[700] : Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
