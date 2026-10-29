import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/shoe.dart';
import '../utils/price_format.dart';

class CartRow extends StatelessWidget {
  const CartRow({
    super.key,
    required this.shoe,
    required this.quantity,
    required this.onMinus,
    required this.onPlus,
  });

  final Shoe shoe;
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 82,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Image.asset(shoe.image, fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shoe.brand,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                Text(
                  shoe.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  '₱ ${formatPrice(shoe.price)}',
                  style: const TextStyle(
                    color: brandBlue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMinus,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          IconButton(
            onPressed: onPlus,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
