import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class PriceLine extends StatelessWidget {
  const PriceLine({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? ink : muted,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: bold ? 16 : 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            fontSize: bold ? 17 : 14,
          ),
        ),
      ],
    );
  }
}
