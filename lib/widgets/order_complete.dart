import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class _CompletionBackgroundPainter extends CustomPainter {
  const _CompletionBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final lightBrush = Paint()
      ..color = const Color(0xFFE9EBEC)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;

    final topBrush = Path()
      ..moveTo(-size.width * .08, size.height * .15)
      ..cubicTo(
        size.width * .18,
        size.height * .02,
        size.width * .30,
        size.height * .04,
        size.width * .48,
        -size.height * .04,
      );
    canvas.drawPath(topBrush, lightBrush);

    final secondBrush = Path()
      ..moveTo(-size.width * .06, size.height * .22)
      ..cubicTo(
        size.width * .18,
        size.height * .13,
        size.width * .30,
        size.height * .12,
        size.width * .49,
        size.height * .04,
      );
    canvas.drawPath(secondBrush, lightBrush);

    final greenBrush = Paint()
      ..color = const Color(0xFF64E900)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    final greenPath = Path()
      ..moveTo(size.width * .68, size.height * .12)
      ..cubicTo(
        size.width * .83,
        size.height * .20,
        size.width * .90,
        size.height * .08,
        size.width * 1.08,
        size.height * .02,
      );
    canvas.drawPath(greenPath, greenBrush);

    final bottomBrush = Path()
      ..moveTo(-size.width * .10, size.height * .91)
      ..cubicTo(
        size.width * .12,
        size.height * .78,
        size.width * .19,
        size.height * .85,
        size.width * .34,
        size.height * 1.08,
      );
    canvas.drawPath(bottomBrush, lightBrush);

    final smallGreen = Path()
      ..moveTo(size.width * .73, size.height * .88)
      ..cubicTo(
        size.width * .86,
        size.height * .80,
        size.width * .91,
        size.height * .91,
        size.width * 1.04,
        size.height * .78,
      );
    canvas.drawPath(smallGreen, greenBrush);

    final speckPaint = Paint()..color = const Color(0xFF6BEA14);

    for (final point in <Offset>[
      Offset(size.width * .76, size.height * .18),
      Offset(size.width * .83, size.height * .15),
      Offset(size.width * .91, size.height * .21),
      Offset(size.width * .18, size.height * .89),
      Offset(size.width * .26, size.height * .93),
      Offset(size.width * .78, size.height * .80),
    ]) {
      canvas.drawCircle(point, 2.2, speckPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionBackgroundPainter oldDelegate) {
    return false;
  }
}

class OrderComplete extends StatelessWidget {
  const OrderComplete({
    super.key,
    required this.paymentMethod,
    required this.onContinue,
  });

  final String paymentMethod;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFF37AFFF),
            width: 1.2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: _CompletionBackgroundPainter(),
              ),
            ),
            Positioned(
              right: -42,
              top: 14,
              child: Transform.rotate(
                angle: -.30,
                child: Opacity(
                  opacity: .92,
                  child: Image.asset(
                    'assets/shoes/black.png',
                    width: 220,
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -70,
              bottom: -45,
              child: Transform.rotate(
                angle: .28,
                child: Opacity(
                  opacity: .25,
                  child: Image.asset(
                    'assets/shoes/black.png',
                    width: 245,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 94,
                      height: 94,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF55D500),
                          width: 7,
                        ),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF55D500),
                        size: 65,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Order Completed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Payment: $paymentMethod',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 185,
                      height: 7,
                      decoration: BoxDecoration(
                        color: const Color(0xFF55D500),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF55D500),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 14,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: onContinue,
                      icon: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      label: const Icon(Icons.arrow_forward, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
