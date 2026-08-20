import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Boton "Continuar con Google" con el aspecto neutro que pide Google:
/// superficie clara, borde tenue, texto oscuro y el logotipo a la izquierda.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.label = 'Continue with Google',
  });

  /// `null` deshabilita el boton.
  final VoidCallback? onPressed;

  /// Sustituye el logotipo por un indicador de progreso y bloquea el boton.
  final bool isLoading;

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      key: const Key('google_login_button'),
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: isLoading
                ? const CircularProgressIndicator(strokeWidth: 2)
                : const GoogleLogo(size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Logotipo de Google dibujado a mano para no arrastrar un asset ni una
/// dependencia de SVG por un icono de 20 px.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  static double _rad(double degrees) => degrees * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.24;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height)
        .deflate(stroke / 2);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Los cuatro tramos del anillo, en sentido horario desde el arco rojo.
    void segment(Color color, double startDeg, double sweepDeg) {
      canvas.drawArc(rect, _rad(startDeg), _rad(sweepDeg), false, arc..color = color);
    }

    segment(_red, 190, 125);
    segment(_blue, 315, 65);
    segment(_green, 20, 70);
    segment(_yellow, 90, 100);

    // Barra horizontal azul: nace en el centro y llega al borde interior.
    final barTop = size.height / 2 - stroke / 2;
    canvas.drawRect(
      Rect.fromLTRB(size.width * 0.48, barTop, size.width - stroke / 2,
          barTop + stroke),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
