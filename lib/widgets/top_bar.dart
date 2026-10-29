import 'package:flutter/material.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.showActions,
    required this.onProfileTap,
    required this.onFavoritesTap,
    required this.onCartTap,
  });

  final bool showActions;
  final VoidCallback onProfileTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 7, 10, 5),
      child: Row(
        children: [
          const Text(
            'KicksCollection',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
          const Spacer(),
          if (showActions) ...[
            IconButton(
              onPressed: onFavoritesTap,
              icon: const Icon(Icons.favorite_border, size: 25),
            ),
            IconButton(
              onPressed: onCartTap,
              icon: const Icon(Icons.shopping_cart_outlined, size: 24),
            ),
          ],
          IconButton(
            onPressed: onProfileTap,
            icon: const Icon(Icons.person, size: 24),
          ),
        ],
      ),
    );
  }
}
