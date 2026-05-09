import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';

const _logoPath = 'lib/assets/icons/logoFav.svg';
const _logoWidth = 72.0;
const _dialogPadding = EdgeInsets.fromLTRB(28, 32, 28, 24);
const _titleStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: AppColors.primary,
);
const _bodyStyle = TextStyle(
  fontSize: 14,
  color: Color(0xFF555555),
  height: 1.5,
);

Widget _dialogLogo() => SvgPicture.asset(_logoPath, width: _logoWidth);

Future<bool> showUnfavoriteConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: _dialogPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogLogo(),
            const SizedBox(height: 20),
            const Text('Desfavoritar hotel', style: _titleStyle),
            const SizedBox(height: 12),
            const Text(
              'Você tem certeza que deseja desfavoritar este hotel?',
              style: _bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Desfavoritar',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

Future<void> showFavoriteAddedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: _dialogPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogLogo(),
            const SizedBox(height: 20),
            const Text('Favorito adicionado!', style: _titleStyle),
            const SizedBox(height: 12),
            const Text(
              'Hotel adicionado aos favoritos com sucesso.',
              style: _bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Entendido',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> showFavoriteRemovedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: _dialogPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogLogo(),
            const SizedBox(height: 20),
            const Text('Favorito removido!', style: _titleStyle),
            const SizedBox(height: 12),
            const Text(
              'Hotel removido dos favoritos com sucesso.',
              style: _bodyStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Entendido',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
